
" 设定默认解码 
set fileencodings=utf-8,ucs-bom,gb18030,gbk,gb2312,cp936
set termencoding=utf-8
set encoding=utf-8

" 显示状态行当前设置
" set statusline= {"[fenc=".(&fenc==""?&enc:&fenc).((exists("+bomb") && &bomb)?"+":"")."]"}
" set laststatus=2
" set statusline=%1*%F%m%r%h%w%=\ %2*\ %Y\ %3*%{\"\".(\"\"?&enc:&fenc).((exists(\"+bomb\")\ &&\ &bomb)?\"+\":\"\").\"\"}\ %4*[%l,%v]\ %5*%p%%\ \|\ %6*%LL\

" 语法高亮
syntax on

" 显示行号
set number 

" 启动文件类型检查"
filetype on 

" 运行vim加载文件类型插件"
filetype plugin on 



" 显示状态栏
set laststatus=0                                            "2总显示最后一个窗口的状态行，1窗口多于一个时显示最后一个窗口的状态行，0不显示最后一个窗口的状态行
"set rulerformat =%72(%2*%<%=\%M%R%w\ \码:%04b\ \标:\%l\行\ %c%V\列\ \%{strftime(\"%H:%M\",getftime(expand(\"%\")))}\ \%n\ \%Y\ \比:%p%%%)                                                  "1920*1080竖屏配置
"set rulerformat =%75(%2*%<%=\%M%R%w\ \编码:%04b\ \编号:%n\ \光标:\%l\行\ \\\%c%V\列\ \修订\ \%{strftime(\"%H:%M\",getftime(expand(\"%\")))}\ \类型:%Y\ \比例:%p%%%)                                                    "1920*1080横屏配置
"set statusline=\ 类型:%Y\ 编码:\%05.3B\ 光标:%02l,%02c%02V\ 比例:%p%%\ 长度:%L\ 修改:%{strftime(\"%H:%M\",getftime(expand(\"%\")))}\ 编号:%01n\ 标记:%01M%01R\ 比例:%P\ 文件:%F
"hi User1 cterm=none ctermfg=13 ctermbg=0    "这一行和set statusline=%1是对应的，其他以此类推，实现了vim的背景透明
 
set rulerformat=%85(%)             "显示文件名和文件路径
set rulerformat+=%12(%1*\%<%.10F\ %*%)             "显示文件名和文件路径
" set rulerformat+=%10(%=%2*\类型：%Y%M%R%H%W\ %*%)        "显示文件类型及文件状态
set rulerformat+=%10(%2*\类型:%Y%M%R%H%W\ %*%)        "显示文件类型及文件状态
set rulerformat+=%10(%3*\编码:%{&ff}\ %{&fenc},%B,%*%)   "显示文件编码类型
"set rulerformat+=%10(%3*\编码:%{&fenc}\ %B\ %*%)   "显示文件编码类型
set rulerformat+=%12(%4*\ %l行/%L\ %c列\ %*%)   "显示光标所在行和列
set rulerformat+=%3(%5*\比例:%2p%%\%*%)            "显示光标前文本所占总文本的比例
hi User1 cterm=none ctermfg=10 ctermbg=0    "这一行和set statusline=%1是对应的，其他以此类推，实现了vim的背景透明
hi User2 cterm=none ctermfg=11 ctermbg=0
hi User3 cterm=none ctermfg=12 ctermbg=0
hi User4 cterm=none ctermfg=13 ctermbg=0
hi User5 cterm=none ctermfg=14 ctermbg=0



