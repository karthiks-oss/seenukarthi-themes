if [ $UID -eq 0 ]; then CARET_COLOR="red"; else CARET_COLOR="reset_color"; fi

local success_code=""
local failure_code=""
local vcs_logo=""
local vcs_change=" "
local chevron_left=""
local chevron_right=""
local devtools_logo="  "
local home_logo=" "
local folder_logo="ﱮ "
local caret_logo=" "
local ssh_logo="殺"

local java_logo="%{$fg[magenta]%}"
local mvn_logo="%{$fg[red]%}"
local gradle_logo="%{$fg[green]%}"
local nodejs_logo="%{$fg[green]%}"
local npm_logo="%{$fg[red]%} "
local bun_logo="%{$fg[yellow]%}󰚅"
local py_logo="%{$fg[green]%}"
local ruby_logo="%{$fg[red]%}󰴭"
local bundler_logo="%{$fg[yellow]%}"
local cargo_logo="%{$fg[yellow]%}󱣘"
local rust_logo="%{$fg[red]%}"
local cmake_logo="%{$fg[red]%}"
local make_logo="%{$fg[green]%}"
local cc_logo="%{$fg[blue]%} "
local swift_logo="%{$fg[magenta]%}"
local asm_logo="%{$fg[blue]%}"

local intellij_logo="%{$fg[blue]%}"

local seperator=" "

local github_logo="%{$fg[black]%} %{${reset_color}%}"
local gitlab_logo="%{$fg[red]%} %{${reset_color}%}"
local bitbucket_logo="%{$fg[blue]%} %{${reset_color}%}"
local space_logo="%{$fg[green]%} %{${reset_color}%}"

local ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[blue]%}${chevron_left}%{$reset_color%}%{$fg[magenta]%}"
local ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg[magenta]%}${vcs_logo}%{$fg[blue]%}${chevron_right}%{$reset_color%}"
local ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[yellow]%}$(tput blink)${vcs_change}$(tput sgr0)%{$reset_color%} "
local ZSH_THEME_GIT_PROMPT_CLEAN=""

local return_code="%(?.%{$fg[green]%}% ${success_code}%{$reset_color%}.%{$fg[red]%}%? ${failure_code}%{$reset_color%})"

my_dev_prompt_info() {
    setopt ksh_arrays
    setopt +o nomatch
    local VER_REGEX='([[:digit:]]+|[[:digit:]]+\.[[:digit:]]+|[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+)'
    local java_found="false" 
    local cc_found="false"
    local i=0;
    declare -a DEV_TOOLS;

    local no_dev_prompt=${NO_DEV_PROMPT:-false}

    if [ "${no_dev_prompt}" = "true" ] || [ "${HOME}" = "${PWD}" ]; then
      return
    fi

    if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]; then
      local remote=$(git remote -v | grep origin | grep "(fetch)" | grep -Eo 'github|gitlab|bitbucket|jetbrains'  | head -1)
      case "$remote" in
          "github")
            DEV_TOOLS[i]="${github_logo}"
            i=$((i+1))
            ;;
          "gitlab")
            DEV_TOOLS[i]="${gitlab_logo}"
            i=$((i+1))
            ;;
          "bitbucket")
            DEV_TOOLS[i]="${bitbucket_logo}"
            i=$((i+1))
            ;;
          "jetbrains")
            DEV_TOOLS[i]="${space_logo}"
            i=$((i+1))
            ;;
      esac
      export CUR_BR=$(parse_git_dirty)
      DEV_TOOLS[i]="$ZSH_THEME_GIT_PROMPT_PREFIX$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_SUFFIX"
      i=$((i+1))
    fi
  
    if [ svn info > /dev/null 2>&1 ]; then
      DEV_TOOLS[i]="${ZSH_THEME_GIT_PROMPT_PREFIX}Rev $(parse_svn_revision) Branch $(parse_svn_branch)${ZSH_THEME_GIT_PROMPT_SUFFIX}"
      i=$((i+1))
    fi

    local devfile=$(eval find ./$(printf "{$(echo %{1..10}q,)}" | sed 's/ /\.\.\//g')/ -maxdepth 1 -name .devprompt)
    
    if [ -f "${devfile}" ]; then
      local devDir=$(dirname ${devfile})
      while read line; do
        # JetBrains
        if [ "${line}" = "jetbrains" ] && [ -d "${devDir}/.idea" ]; then
          DEV_TOOLS_VERSION=''
          DEV_TOOLS[i]="${intellij_logo}"
          i=$((i+1))
        fi

        # Java
        if [[ "${line}" = "java" ]]; then
          # Java
          if [ -x "$(command -v java)" ]; then
            DEV_TOOLS_VERSION=`java -version 2>&1 |awk 'NR==1{ gsub(/"/,""); print $3 }'`
            DEV_TOOLS[i]="$(prase_version_info ${java_logo} ${DEV_TOOLS_VERSION})"
            i=$((i+1))
          fi

          # Gradle
          files=""
          files=$(find ${devDir} \( -name "*.gradle" -or -name "*.gradle.kts" -or -name "gradlew" \) -maxdepth 1 | awk 'NR==1{ gsub(/"/,""); print $1 }') 2> /dev/null
          if [ ! -z "${files}" ]; then
            if test -f "${devDir}/gradlew"; then
              DEV_TOOLS_VERSION=`${devDir}/gradlew -version 2>&1 |awk 'NR==3{ gsub(/"/,""); print $2 }'`
              DEV_TOOLS[i]="$(prase_version_info ${gradle_logo}W ${DEV_TOOLS_VERSION})"
              i=$((i+1))
            elif [ -x "$(command -v gradle)" ]; then
              DEV_TOOLS_VERSION=`gradle -version 2>&1 |awk 'NR==3{ gsub(/"/,""); print $2 }'`
              DEV_TOOLS[i]="$(prase_version_info ${gradle_logo} ${DEV_TOOLS_VERSION})"
              i=$((i+1))
            fi
          fi

          # Maven
          if [ -f "${devDir}/pom.xml" ]; then
            if [ -x "$(command -v mvn)" ]
            then
              DEV_TOOLS_VERSION=`mvn -v 2>&1 | awk 'NR==1{ gsub(/"/,""); print $4 }'`
              DEV_TOOLS[i]="$(prase_version_info ${mvn_logo} ${DEV_TOOLS_VERSION})"
              i=$((i+1))
            else [ -x "$(command -v maven)" ]
              DEV_TOOLS_VERSION=`maven -v 2>&1 | awk 'NR==1{ gsub(/"/,""); print $4 }'`
              DEV_TOOLS[i]="$(prase_version_info ${mvn_logo} ${DEV_TOOLS_VERSION})"
              i=$((i+1))
            fi
          fi

          # Ant
          if [ -f "${devDir}/build.xml" ]; then
            java_found="true"
            if [ -x "$(command -v ant)" ]
            then
              DEV_TOOLS_VERSION=`ant -version | awk 'NR==1' | grep -Eo ${VER_REGEX} | head -1`
              DEV_TOOLS[i]="$(prase_version_info Ant ${DEV_TOOLS_VERSION})"
              i=$((i+1))
            fi
          fi
        fi
        
        # NodeJS
        if [[ "${line}" = "nodejs" ]]; then
          if [ -x "$(command -v node)" ]; then
            DEV_TOOLS_VERSION=`node -v 2>&1 | grep -Eo ${VER_REGEX} | head -1`
            DEV_TOOLS[i]="$(prase_version_info ${nodejs_logo} ${DEV_TOOLS_VERSION})"
            i=$((i+1))
          fi
          
          if [ -x "$(command -v npm)" ]; then
            DEV_TOOLS_VERSION=`npm -v | grep -Eo ${VER_REGEX} | head -1`
            DEV_TOOLS[i]="$(prase_version_info ${npm_logo} ${DEV_TOOLS_VERSION})"
            i=$((i+1))
          fi
        fi

        # Bun
        if [[ "${line}" = "bun" ]]; then
          if [ -x "$(command -v bun)" ]; then
            DEV_TOOLS_VERSION=`bun -v | grep -Eo ${VER_REGEX} | head -1`
            DEV_TOOLS[i]="$(prase_version_info ${bun_logo} ${DEV_TOOLS_VERSION})"
            i=$((i+1))
          fi
        fi

        # Ruby
        if [[ "${line}" = "ruby" ]]; then
          if [ -x "$(command -v ruby)" ]; then
            DEV_TOOLS_VERSION=`ruby -v 2>&1 | grep -Eo ${VER_REGEX} | head -1`
            DEV_TOOLS[i]="$(prase_version_info ${ruby_logo} ${DEV_TOOLS_VERSION})"
            i=$((i+1))
          fi
          if [ -f "${devDir}/Gemfile" ] && [ -x "$(command -v bundle)" ]; then   
            DEV_TOOLS_VERSION=`bundle -v 2>&1 | grep -Eo ${VER_REGEX} | head -1`
            DEV_TOOLS[i]="$(prase_version_info ${bundler_logo} ${DEV_TOOLS_VERSION})"
            i=$((i+1))
          fi
        fi

        # Python
        if [[ "${line}" = "python" ]]; then
          if [ "$(declare -fF conda)" ]; then
              CONDA_VER=`conda env list | grep '*'| cut -d ' ' -f 1`
              CONDA_VER=" (${CONDA_VER})"
          else
              CONDA_VER=""
          fi
          if [ -x "$(command -v python)" ]; then
              DEV_TOOLS_VERSION=`python -V | grep -Eo ${VER_REGEX} | head -1`
              DEV_TOOLS[i]="$(prase_version_info ${py_logo} ${DEV_TOOLS_VERSION}${CONDA_VER})"
              i=$((i+1))
          elif [ -x "$(command -v python3)" ]; then
              DEV_TOOLS_VERSION=`python3 -V | grep -Eo ${VER_REGEX} | head -1`
              DEV_TOOLS[i]="$(prase_version_info ${py_logo} ${DEV_TOOLS_VERSION}${CONDA_VER})"
              i=$((i+1))
          fi
        fi
        
        # C/CPP
        if [[ "${line}" = "cc" ]]; then
          local cc_exe=${CC:-gcc}
          if [ -x "$(command -v ${cc_exe})" ]; then
            CC_VERSION=`${cc_exe} --version | awk 'NR==1' | grep -Eo ${VER_REGEX} | head -1`
            CC_FLAVOUR=`${cc_exe} --version | awk 'NR==1' | grep -Eo 'Apple clang|Homebrew GCC' | head -1`

            if [ "${CC_FLAVOUR}" = "" ]; then
              CC_FLAVOUR=`${cc_exe} --version | awk 'NR==1' | grep -Eo 'clang|GCC|gcc' | head -1`
            fi
            CC_FLAVOUR=" (${CC_FLAVOUR})"
            DEV_TOOLS[i]="$(prase_version_info ${cc_logo} ${CC_VERSION}${CC_FLAVOUR})"
            i=$((i+1))
          fi

          if [ -f "${devDir}/CMakeLists.txt" ]; then
            if [ -x "$(command -v cmake)" ]; then
              CMAKE_VERSION=`cmake --version | awk 'NR==1' | grep -Eo ${VER_REGEX} | head -1`
              DEV_TOOLS[i]="$(prase_version_info ${cmake_logo} ${CMAKE_VERSION})"
              i=$((i+1))
            fi
          fi

          if [ -f "${devDir}/GNUmakefile" ] || [ -f "${devDir}/makefile" ] || [ -f "${devDir}/Makefile" ]; then
            if [ -x "$(command -v make)" ]; then
              MAKE_VERSION=`make --version | awk 'NR==1' | grep -Eo ${VER_REGEX} | head -1`
              DEV_TOOLS[i]="$(prase_version_info ${make_logo} ${MAKE_VERSION})"
              i=$((i+1))
            fi
          fi
        fi

        # ASM
        if [[ "${line}" = "asm" ]]; then
          if [ -x "$(command -v nasm)" ]; then
            DEV_TOOLS_VERSION=`nasm --version | grep -Eo ${VER_REGEX} | head -1`
            DEV_TOOLS[i]="$(prase_version_info ${asm_logo} ${DEV_TOOLS_VERSION})"
            i=$((i+1))
          fi
          if [ -f "${devDir}/GNUmakefile" ] || [ -f "${devDir}/makefile" ] || [ -f "${devDir}/Makefile" ]; then
            if [ -x "$(command -v make)" ]; then
              MAKE_VERSION=`make --version | awk 'NR==1' | grep -Eo ${VER_REGEX} | head -1`
              DEV_TOOLS[i]="$(prase_version_info ${make_logo} ${MAKE_VERSION})"
              i=$((i+1))
            fi
          fi
        fi

        # Rust
        if [[ "${line}" = "rust" ]]; then
          if [ -f "${devDir}/Cargo.toml" ] || [ -x "$(command -v cargo)" ]; then
            DEV_TOOLS_VERSION=`cargo --version | grep -Eo ${VER_REGEX} | head -1`
            DEV_TOOLS[i]="$(prase_version_info ${cargo_logo} ${DEV_TOOLS_VERSION})"
            i=$((i+1))
          fi

          if [ -x "$(command -v rustc)" ]; then
            DEV_TOOLS_VERSION=`rustc --version | grep -Eo ${VER_REGEX} | head -1`
            DEV_TOOLS[i]="$(prase_version_info ${rust_logo} ${DEV_TOOLS_VERSION})"
            i=$((i+1))
          fi
        fi

        # Swift
        if [[ "${line}" = "swift" ]]; then
          if [ -f "${devDir}/Package.swift" ] || [ -x "$(command -v swift)" ]; then
            DEV_TOOLS_VERSION=`swift --version | grep -Eo ${VER_REGEX} | head -1`
            DEV_TOOLS[i]="$(prase_version_info ${swift_logo} ${DEV_TOOLS_VERSION})"
            i=$((i+1))
          fi
        fi

      done < ${devfile}
            
    fi
    if (( ${#DEV_TOOLS[@]} > 0 )); then
      RET=${RET}`prompt_end`
      RET=${RET}${devtools_logo}
      RET=${RET}${(j: :)DEV_TOOLS[@]}
      RET=${RET}''
      echo ${RET}
    fi
    setopt +o nomatch
    RET="";
}

prase_version_info() {
  echo "%{$BOLD%}${chevron_left}%{${reset_color}%}$1${seperator}$2${chevron_right}%{${reset_color}%}"
}

parse_svn_branch() {
  parse_svn_url | sed -e 's#^'"$(parse_svn_repository_root)"'##g' | egrep -o '(tags|branches)/[^/]+|trunk' | egrep -o '[^/]+$' | awk '{print ""$1"" }'
}

parse_svn_url() {
  svn info 2>/dev/null | sed -ne 's#^URL: ##p'
}

parse_svn_repository_root() {
  svn info 2>/dev/null | sed -ne 's#^Repository Root: ##p'
}

parse_svn_revision(){
  svn info 2>/dev/null | awk 'NR==7' | cut -d ' ' -f 2 cd 
}

is_ssh(){
  if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    RET="";
    RET=${RET}`prompt_end`
    RET=${RET}"${ssh_logo} %{$fg[cyan]%}%n%{$fg[yellow]%}@%{$fg[blue]%}%M%{${reset_color}%}"
    RET=${RET}''
    echo ${RET}
  else
    return
  fi
}

# Checks if working tree is dirty
parse_git_dirty() {
  ref=$(git symbolic-ref HEAD 2> /dev/null)
  isDetached=`git branch --show-current | wc -l`
  local endl;
  if [ "${isDetached}" = "0" ]; then
    endl=""
  else
    endl=" "
  fi

  if [[ -n $(git status -s --ignore-submodules=dirty 2> /dev/null) ]]; then
    echo "${ITALIC_ON}${ref#refs/heads/} $ZSH_THEME_GIT_PROMPT_DIRTY${RESET_FORMATTING}"
  else
    echo "${ref#refs/heads/}${endl}$ZSH_THEME_GIT_PROMPT_CLEAN"
  fi
}

prompt_end(){
  print -n "\n%{%f%}"
}

get_dir_icon(){
  if [ "${HOME}" = "${PWD}" ]; then
    echo "${home_logo}"
  else
    echo "${folder_logo}"
  fi
}

PROMPT='';
PROMPT=${PROMPT}'$(is_ssh)'
PROMPT=${PROMPT}'$(my_dev_prompt_info)'
PROMPT=${PROMPT}'$(prompt_end)'
PROMPT=${PROMPT}'$(get_dir_icon)%{$fg[green]%} %50<...<%~%<< %{$reset_color%}% '
PROMPT=${PROMPT}'$(prompt_end)'
PROMPT=${PROMPT}'%{${fg[$CARET_COLOR]}%}${caret_logo}%{${reset_color}%} '
RPS1="${return_code}"
RPS2="${return_code}"
