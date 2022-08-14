if [ $UID -eq 0 ]; then CARETCOLOR="red"; else CARETCOLOR="blue"; fi

local return_code="%(?.%{$fg[green]%}% ✔%{$reset_color%}.%{$fg[red]%}%? ✘%{$reset_color%})"

my_dev_prompt_info() {

    local no_dev_prompt=${NO_DEV_PROMPT:-false}
    local VER_REGEX='[0-9]+\.[0-9]+\.[0-9]+'

    if [ "${no_dev_prompt}" = "true" ] || [ "${HOME}" = "${PWD}" ]; then
      return
    fi

    setopt ksh_arrays
    setopt +o nomatch
    declare -a DEV_TOOLS;
    i=0;

    local java_found="false" 

    if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]; then
      DEV_TOOLS[i]="$ZSH_THEME_GIT_PROMPT_PREFIX$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_SUFFIX"
      i=$((i+1))
    fi

    if [ svn info > /dev/null 2>&1 ]; then
      DEV_TOOLS[i]="${ZSH_THEME_GIT_PROMPT_PREFIX}Rev $(parse_svn_revision) Branch $(parse_svn_branch)${ZSH_THEME_GIT_PROMPT_SUFFIX}"
      i=$((i+1))
    fi

    files=$(find ${PWD} \( -name "*.gradle" -or -name "*.gradle.kts" -or -name "gradlew" \) -maxdepth 1 | awk 'NR==1{ gsub(/"/,""); print $1 }') 2> /dev/null

    if [ ! -z "${files}" ]; then
      java_found="true"
      if test -f "gradlew"; then
        DEV_TOOLS_VERSION=`./gradlew -version 2>&1 |awk 'NR==3{ gsub(/"/,""); print $2 }'`
        DEV_TOOLS[i]="$(prase_version_info GradleW ${DEV_TOOLS_VERSION})"
        i=$((i+1))
      elif [ -x "$(command -v gradle)" ]; then
        DEV_TOOLS_VERSION=`gradle -version 2>&1 |awk 'NR==3{ gsub(/"/,""); print $2 }'`
        DEV_TOOLS[i]="$(prase_version_info Gradle ${DEV_TOOLS_VERSION})"
        i=$((i+1))
      fi
    fi

    if [ -f "pom.xml" ]; then
      java_found="true"
      if [ -x "$(command -v mvn)" ]
      then
        DEV_TOOLS_VERSION=`mvn -v 2>&1 | awk 'NR==1{ gsub(/"/,""); print $4 }'`
        DEV_TOOLS[i]="$(prase_version_info Maven ${DEV_TOOLS_VERSION})"
        i=$((i+1))
      else [ -x "$(command -v maven)" ]
        DEV_TOOLS_VERSION=`maven -v 2>&1 | awk 'NR==1{ gsub(/"/,""); print $4 }'`
        DEV_TOOLS[i]="$(prase_version_info Maven ${DEV_TOOLS_VERSION})"
        i=$((i+1))
      fi
    fi 

    files=""
    files=$(find ${PWD} \( -name "*.java" \)  -maxdepth 1 | awk 'NR==1{ gsub(/"/,""); print $1 }') 2> /dev/null

    if [ "${java_found}" = "true" ] || [ ! -z "${files}" ]; then
      if [ -x "$(command -v java)" ]; then
        DEV_TOOLS_VERSION=`java -version 2>&1 |awk 'NR==1{ gsub(/"/,""); print $3 }'`
        DEV_TOOLS[i]="$(prase_version_info Java ${DEV_TOOLS_VERSION})"
        i=$((i+1))
      fi
    fi

    files=""
    files=$(find ${PWD} \( -name "package.json" -or -name "*.js" \) -maxdepth 1 | awk 'NR==1{ gsub(/"/,""); print $1 }') 2> /dev/null

    if [ ! -z "${files}" ]; then
      if [ -x "$(command -v node)" ]; then
        DEV_TOOLS_VERSION=`node -v 2>&1 | grep -Eo ${VER_REGEX} | head -1`
        DEV_TOOLS[i]="$(prase_version_info Node ${DEV_TOOLS_VERSION})"
        i=$((i+1))
      fi
      
      if [ -x "$(command -v npm)" ]; then
        DEV_TOOLS_VERSION=`npm -v | grep -Eo ${VER_REGEX} | head -1`
        DEV_TOOLS[i]="$(prase_version_info NPM ${DEV_TOOLS_VERSION})"
        i=$((i+1))
      fi

      if [ -x "$(command -v bun)" ]; then
        DEV_TOOLS_VERSION=`bun -v | grep -Eo ${VER_REGEX} | head -1`
        DEV_TOOLS[i]="$(prase_version_info Bun ${DEV_TOOLS_VERSION})"
        i=$((i+1))
      fi
    fi

    if [ -f "Gemfile" ]; then
      if [ -x "$(command -v ruby)" ]; then
        DEV_TOOLS_VERSION=`ruby -v 2>&1 | grep -Eo ${VER_REGEX} | head -1`
        DEV_TOOLS[i]="$(prase_version_info Ruby ${DEV_TOOLS_VERSION})"
        i=$((i+1))
      fi
    fi

    files=""
    files=$(find ${PWD} \( -name ".pyinfo" -or -name "requirements.txt" -or -name "*.py" \) -maxdepth 1 | awk 'NR==1{ gsub(/"/,""); print $1 }') 2> /dev/null

    if [ ! -z "${files}" ]; then
      if [ -x "$(command -v python3)" ]; then
          DEV_TOOLS_VERSION=`python3 -V | grep -Eo ${VER_REGEX} | head -1`
          DEV_TOOLS[i]="$(prase_version_info Python ${DEV_TOOLS_VERSION})"
          i=$((i+1))
      fi
    fi

    files=""
    files=$(find ${PWD} \( -name "CMakeLists.txt" -or -name "*.c" -or -name "*.h" -or -name "*.cpp" \) -maxdepth 1 | awk 'NR==1{ gsub(/"/,""); print $1 }') 2> /dev/null

    if [ ! -z "${files}" ]; then
      if [ -x "$(command -v cmake)" ]; then
        CMAKE_VERSION=`cmake --version | awk 'NR==1' | grep -Eo ${VER_REGEX} | head -1`
        DEV_TOOLS[i]="$(prase_version_info CMake ${CMAKE_VERSION})"
        i=$((i+1))
      fi
      local cc_exe=${CC:-gcc}
      if [ -x "$(command -v ${cc_exe})" ]; then
        CC_VERSION=`${cc_exe} --version | awk 'NR==1' | grep -Eo ${VER_REGEX} | head -1`
        CC_FLAVOUR=`${cc_exe} --version | awk 'NR==1' | egrep -o 'Apple clang|gcc|GCC|Homebrew GCC'`
        DEV_TOOLS[i]="$(prase_version_info ${CC_FLAVOUR} ${CC_VERSION})"
        i=$((i+1))
      fi
    fi

    files=""
    files=$(find ${PWD} \( -name "Cargo.toml" \) -maxdepth 1 | awk 'NR==1{ gsub(/"/,""); print $1 }') 2> /dev/null

    if [ ! -z "${files}" ]; then
      if [ -x "$(command -v cargo)" ]; then
        DEV_TOOLS_VERSION=`cargo --version | grep -Eo ${VER_REGEX} | head -1`
        DEV_TOOLS[i]="$(prase_version_info Cargo ${DEV_TOOLS_VERSION})"
        i=$((i+1))
      fi

      if [ -x "$(command -v rustc)" ]; then
        DEV_TOOLS_VERSION=`rustc --version | grep -Eo ${VER_REGEX} | head -1`
        DEV_TOOLS[i]="$(prase_version_info Rust ${DEV_TOOLS_VERSION})"
        i=$((i+1))
      fi
    fi

    setopt +o nomatch
    RET="";

    if (( ${#DEV_TOOLS[@]} > 0 )); then
      RET=${RET}`prompt_end`
      RET=${RET}'[🛠  '
      RET=${RET}${(j: :)DEV_TOOLS[@]}
      RET=${RET}']'
      echo ${RET}
    else
      return
    fi
}

prase_version_info() {
  echo "%{${fg_bold[blue]}%}«%{${fg_bold[yellow]}%}$1%{${fg_bold[blue]}%}:%{${fg_bold[red]}%}$2%{${fg_bold[blue]}%}»%{${reset_color}%}"
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
  svn info 2>/dev/null | awk 'NR==7' | cut -d ' ' -f 2 
}

is_ssh(){
  if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    RET="";
    RET=${RET}`prompt_end`
    RET=${RET}"[📠  %{$fg_bold[magenta]%}%n%{$fg_bold[blue]%}@%{$fg_bold[magenta]%}%m%{${reset_color}%}"
    RET=${RET}' ]'
    echo ${RET}
  else
    return
  fi
}

# Checks if working tree is dirty
parse_git_dirty() {
  ref=$(git symbolic-ref HEAD 2> /dev/null)
  if [[ -n $(git status -s --ignore-submodules=dirty 2> /dev/null) ]]; then
    echo "${ref#refs/heads/}$ZSH_THEME_GIT_PROMPT_DIRTY"
  else
    echo "${ref#refs/heads/}"
  fi
}

prompt_end(){
  print -n "\n%{%f%}"
}

get_dir_icon(){
  if [ "${HOME}" = "${PWD}" ]; then
    echo "🏠"
  else
    echo "📁"
  fi
}

PROMPT='';
PROMPT=${PROMPT}'$(is_ssh)'
PROMPT=${PROMPT}'$(my_dev_prompt_info)'
PROMPT=${PROMPT}'$(prompt_end)'
PROMPT=${PROMPT}'%{${fg[green]}%}[$(get_dir_icon) %50<...<%~%<<]%{$reset_color%}% '
PROMPT=${PROMPT}'$(prompt_end)'
PROMPT=${PROMPT}'[%{${fg_bold[$CARETCOLOR]}%}~>%{${reset_color}%} '
RPS1="${return_code}]"
RPS2="${return_code}]"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}«%{$reset_color%}%{$fg_bold[yellow]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX=" %{$fg_bold[red]%}\ue0a0%{$fg_bold[blue]%}»%{$reset_color%}"
