package require Tk

# 加载扩展
catch {load ./libllama_tcl.dylib Llama}

# --- 全局变量 ---
set handle ""
set model_path "/Users/vajra/.llama/models/qwen3-4b-instruct.gguf"
set font_size 18
set base_font "Consolas"
set max_history 1000
set concise_mode true  ;# 简洁模式开关

# --- 颜色配置 (参考 OpenAI ChatGPT 风格) ---
set bg_color "#ffffff"
set user_bg "#f7f7f8"
set ai_bg "#ffffff"
set user_fg "#000000"
set ai_fg "#10a37f"
set system_fg "#6e6e80"
set border_color "#e5e5e5"

# --- 字体标签和配置 ---
proc update_fonts {} {
    global font_size base_font
    .t configure -font [list $base_font $font_size]
    .f.e configure -font [list $base_font $font_size]
    .t tag configure user -font [list $base_font $font_size]
    .t tag configure assistant -font [list $base_font $font_size]
    .t tag configure system -font [list "$base_font Bold" $font_size]
}

# --- GUI 布局 ---
wm title . "Llama Chat - Tcl AI Assistant"
wm geometry . 900x700
. configure -bg $bg_color

# 创建文本显示区域
text .t \
    -width 90 \
    -height 35 \
    -wrap word \
    -yscrollcommand ".sb set" \
    -bg $bg_color \
    -fg $user_fg \
    -borderwidth 0 \
    -highlightthickness 0 \
    -padx 20 \
    -pady 20

scrollbar .sb -command ".t y view" -bg $bg_color

# 配置文本标签样式
.t tag configure user \
    -background $user_bg \
    -foreground $user_fg \
    -lmargin1 10 \
    -lmargin2 10 \
    -rmargin 10

.t tag configure assistant \
    -background $ai_bg \
    -foreground $ai_fg \
    -lmargin1 10 \
    -lmargin2 10 \
    -rmargin 10

.t tag configure system \
    -foreground $system_fg \
    -font [list "$base_font Bold" $font_size] \
    -justify center

.t tag configure separator \
    -foreground $border_color

# 底部控制面板
frame .control -bg $border_color -height 2
pack .control -side bottom -fill x

# 输入框框架
frame .f -bg $user_bg -borderwidth 1 -relief solid
pack .f -side bottom -fill x -padx 20 -pady 10

entry .f.e \
    -width 80 \
    -font [list $base_font $font_size] \
    -bg $bg_color \
    -fg $user_fg \
    -borderwidth 0 \
    -highlightthickness 0

button .f.bclear \
    -text "Clear" \
    -command clear_conversation \
    -font [list "$base_font" $font_size] \
    -bg "#ff6b6b" \
    -fg "#ffffff" \
    -borderwidth 0 \
    -padx 15 \
    -pady 8 \
    -cursor hand2

button .f.b \
    -text "Send" \
    -command on_send \
    -font [list "$base_font Bold" $font_size] \
    -bg $ai_fg \
    -fg "#ffffff" \
    -borderwidth 0 \
    -padx 20 \
    -pady 8 \
    -cursor hand2

button .f.bplus \
    -text "+" \
    -command increase_font \
    -font [list $base_font [expr {$font_size - 2}]] \
    -bg $border_color \
    -fg $user_fg \
    -borderwidth 0 \
    -padx 8 \
    -pady 4 \
    -cursor hand2

button .f.bminus \
    -text "-" \
    -command decrease_font \
    -font [list $base_font [expr {$font_size - 2}]] \
    -bg $border_color \
    -fg $user_fg \
    -borderwidth 0 \
    -padx 8 \
    -pady 4 \
    -cursor hand2

button .f.bmode \
    -text "🎯" \
    -command toggle_mode \
    -font [list $base_font $font_size] \
    -bg "#4CAF50" \
    -fg "#ffffff" \
    -borderwidth 0 \
    -padx 10 \
    -pady 4 \
    -cursor hand2

# 字体控制按钮和清空按钮在左侧
pack .f.bclear -side left -padx 5
pack .f.bplus -side left -padx 2
pack .f.bminus -side left -padx 2
pack .f.bmode -side left -padx 2
# 输入框在中间
pack .f.e -side left -fill x -expand true -padx 10
# 发送按钮在右侧
pack .f.b -side right -padx 5

# 滚动条和文本框
pack .sb -side right -fill y
pack .t -side left -fill both -expand true

# 初始化字体
update_fonts

# --- 字体控制 ---
proc increase_font {} {
    global font_size
    if {$font_size < 24} {
        incr font_size 2
        update_fonts
    }
}

proc decrease_font {} {
    global font_size
    if {$font_size > 8} {
        incr font_size -2
        update_fonts
    }
}

# --- 模式切换 ---
proc toggle_mode {} {
    global concise_mode
    set concise_mode [expr {!$concise_mode}]

    if {$concise_mode} {
        .f.bmode configure -bg "#4CAF50" -text "🎯"
        .t insert end "\n\[System: 已切换到简洁模式\]\n" system
    } else {
        .f.bmode configure -bg "#FF9800" -text "💬"
        .t insert end "\n\[System: 已切换到详细模式\]\n" system
    }
    .t see end
}

# --- 清空对话 ---
proc clear_conversation {} {
    global handle

    # 重建会话（清空上下文）
    set model_path [llama_get_model_path]
    if {$handle ne ""} {
        llama_destroy $handle
    }
    set handle [llama_create $model_path 2048 0]

    # 清空显示
    .t delete 1.0 end
    .t insert end "========================================\n" separator
    .t insert end "Conversation cleared. Ready for new chat!\n\n" system
    .t insert end "========================================\n\n" separator
    .t see end
}

# --- 获取模型路径（辅助函数）---
proc llama_get_model_path {} {
    global model_path
    return $model_path
}

# --- 初始化模型 ---
proc init_model {} {
    global handle model_path

    .t insert end "========================================\n" separator
    .t insert end "Llama Chat Assistant\n\n" system
    .t insert end "Loading model...\n" system
    update

    if {[catch {set handle [llama_create $model_path 2048 0]} err]} {
        .t insert end "Error loading model: $err\n" system
        set handle ""
    } else {
        .t insert end "Model loaded successfully!\n\n" system
        .t insert end "========================================\n\n" separator
        .t insert end "Type your message below and press Enter to chat.\n\n" system
    }
    .t see end
}

# --- 流式回调函数 ---
proc update_display {text} {
    # 过滤 <thinking> 标签和对话标记
    set filtered $text

    # 过滤 <thinking>...</thinking> 标签
    set filtered [regsub -all {<thinking>.*?</thinking>} $filtered ""]
    set filtered [regsub -all {<thinking>.*?$} $filtered ""]

    # 过滤 ChatML 标记
    set filtered [regsub -all {<\|im_start\|>\w*\n?} $filtered ""]
    set filtered [regsub -all {<\|im_end\|>\n?} $filtered ""]

    # 过滤对话标记
    set filtered [string map {"用户：" "" "助手：" "" "Assistant:" "" "User:" ""} $filtered]
    set filtered [regsub -all {用户[：:]\s*|助手[：:]\s*|Assistant:\s*|User:\s*} $filtered ""]

    # 过滤重复的指令
    set filtered [regsub -all {请简洁回答：|用一两句话简要回答：|（请简短回答）|简要。} $filtered ""]

    if {$filtered ne ""} {
        .t insert end $filtered assistant
        .t see end
    }
    update
}

# --- 发送消息 ---
proc on_send {} {
    global handle
    set input [.f.e get]
    if {$input eq ""} return

    if {$handle eq ""} {
        .t insert end "Error: Model not loaded.\n\n" system
        .t see end
        .f.e delete 0 end
        return
    }

    .f.e delete 0 end
    .f.b configure -state disabled -text "Generating..."
    update

    # 显示用户输入
    .t insert end "========================================\n" separator
    .t insert end "You:\n" system
    .t insert end "$input\n\n" user

    # 构建 prompt（使用ChatML格式，单轮对话模式）
    global concise_mode

    # 单轮对话：每次只包含当前问题，不累积历史
    set prompt "<|im_start|>user\n${input}<|im_end|>\n<|im_start|>assistant\n"

    # 每次对话前重建会话，避免KV cache累积问题
    set model_path [llama_get_model_path]
    llama_destroy $handle
    set handle [llama_create $model_path 2048 0]

    # 发送给模型
    if {[catch {llama_prompt $handle $prompt} err]} {
        .t insert end "Error: $err\n\n" system
        .t see end
        .f.b configure -state normal -text "Send"
        return
    }

    # 流式生成（根据模式调整参数）
    .t insert end "Assistant:\n" system
    update

    # 参数说明：
    # 简洁模式：max_tokens=256, temp=0.5, top_p=0.75（低温输出更确定、简洁）
    # 详细模式：max_tokens=4096, temp=0.7, top_p=0.9（允许更长输出）
    if {$concise_mode} {
        set result [llama_generate $handle 256 0.5 0.75 update_display]
    } else {
        set result [llama_generate $handle 4096 0.7 0.9 update_display]
    }


    .t insert end "\n\n"
    .t see end
    .f.b configure -state normal -text "Send"
}

# --- 键盘绑定 ---
bind .f.e <Return> on_send
bind .f.e <Control-plus> increase_font
bind .f.e <Control-minus> decrease_font
bind . <Command-plus> increase_font
bind . <Command-minus> decrease_font

# --- 启动 ---
after 100 init_model
focus .f.e
