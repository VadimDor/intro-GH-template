#!/usr/bin/env bash

set -euo pipefail

HELP="
Usage:

bash [--github | --gitlab] $0 PLUGIN_NAME TOOL_TEST GH_USER AUTHOR_NAME TOOL_GH TOOL_PAGE LICENSE TESTS

All arguments are optional and will be interactively prompted when not given.

PLUGIN_NAME.
   A name for your new plugin always starting with \`asdf-\` prefix.

TOOL_TEST.
   A shell command used to test correct installation.
   Normally this command is something taking \`--version\` or \`--help\`.

GH_USER.
   Your GitHub/GitLab username.

AUTHOR_NAME.
   Your name, used for licensing.

TOOL_GH.
   The tool's GitHub homepage. Default installation process will try to use
   this to access GitHub releases.

TOOL_PAGE.
   Documentation site for tool usage, mostly informative for users.

LICENSE.
   A license keyword.
   https://help.github.com/en/github/creating-cloning-and-archiving-repositories/licensing-a-repository#searching-github-by-license-type

TESTS.
	I am going to test with BATS and Docker. Please install templates 
"
HELP_PLUGIN_NAME="Name for your plugin, starting with \`asdf-\`, eg. \`asdf-foo\`"
HELP_TOOL_CHECK="Shell command for testing correct tool installation. eg. \`foo --version\` or \`foo --help\`"
HELP_TOOL_REPO="The tool's GitHub homepage."
HELP_TOOL_HOMEPAGE="The tool's documentation homepage if necessary."

camel_case() {
 local word="$1"	
 echo "$(tr '[:lower:]' '[:upper:]' <<< ${word:0:1})${word:1}"
}

ask_for() {
	local prompt="$1"
	local default_value="${2:-}"
	local alternatives="${3:-"[$default_value]"}"
	local value=""

	while [ -z "$value" ]; do
		echo "$prompt" >&2
		if [ "[]" != "$alternatives" ]; then
			echo -n "$alternatives " >&2
		fi
		echo -n "> " >&2
		read -r value
		echo >&2
		if [ -z "$value" ] && [ -n "$default_value" ]; then
			value="$default_value"
		fi
	done

	printf "%s\n" "$value"
}

download_license() {
	local keyword file
	keyword="$1"
	file="$2"

	curl -qsL "https://raw.githubusercontent.com/github/choosealicense.com/gh-pages/_licenses/${keyword}.txt" |
		extract_license >"$file"
}

extract_license() {
	awk '/^---/{f=1+f} f==2 && /^$/ {f=3} f==3'
}

test_url() {
	curl -fqsL -I "$1" | head -n 1 | grep 200 >/dev/null
}

ask_license() {
	local license keyword

	printf "%s\n" "Please choose a LICENSE keyword." >&2
	printf "%s\n" "See available license keywords at" >&2
	printf "%s\n" "https://help.github.com/en/github/creating-cloning-and-archiving-repositories/licensing-a-repository#searching-github-by-license-type" >&2

	while true; do
		license="$(ask_for "License keyword:" "APACHE-2.0" "MIT/APACHE-2.0/MPL-2.0/AGPL-3.0")"
		keyword=$(echo "$license" | tr '[:upper:]' '[:lower:]')

		url="https://choosealicense.com/licenses/$keyword/"
		if test_url "$url"; then
			break
		else
			printf "Invalid license keyword: %s\n" "$license"
		fi
	done

	printf "%s\n" "$keyword"
}

set_placeholder() {
	local name value out file tmpfile
	name="$1"
	value="$2"
	out="$3"

	git grep -P -l -F --untracked "$name" -- "$out" |
		while IFS=$'\n' read -r file; do
			tmpfile="$file.sed"
			sed "s#$name#$value#g" "$file" >"$tmpfile" && mv "$tmpfile" "$file"
		done
}

setup_git() {
	local cwd out tool_name tool_repo check_command author_name github_username tool_homepage ok primary_branch \
	  git bats_tests user_email user_profile pext user_avatar

	cwd="$PWD"
	out="$cwd/out"
	git="${1}"
	

	# ask for arguments not given via CLI
	tool_name="${2:-$(ask_for "$HELP_PLUGIN_NAME")}"

	#tool_name="${tool_name/asdf-/}"

	check_command="${3:-$(ask_for "$HELP_TOOL_CHECK" "${tool_name/asdf-/} --version")}"
    
	url=$(git config --list| grep "remote.origin.url=")  
	t="${url#*$1.com/}"
	org="${t%%/*}"
    git_usernamer=$(printf '%s\n' "$org")
	git_username="${4:-$(ask_for "Your $(camel_case $git) username" "$git_usernamer")}"

	author_name="${5:-$(ask_for "Your name" "$(git config user.name 2>/dev/null)")}"

	tool_repo="${6:-$(ask_for "$HELP_TOOL_REPO" "https://$1.com/$git_username/$tool_name")}"

	tool_homepage="https://$git_username.$1.io/$tool_name"
	tool_homepage="${7:-$(ask_for "$HELP_TOOL_HOMEPAGE" "$tool_homepage")}"

	license_keyword="${8:-$(ask_license)}"
	license_keyword="$(echo "$license_keyword" | tr '[:upper:]' '[:lower:]')"

	bats_tests="${9:-$(ask_for "Type \`yes\` if you want preinstall environment and samples for BATS tests." "yes")}"
	bats_tests=$(echo "$bats_tests" | tr '[:upper:]' '[:lower:]')
	[[ $bats_tests == "tests" ]] && bats_tests="yes"

	user_profile="https://$git.com/$git_username"
	primary_branch="main"

	cat <<-EOF
		Setting up plugin: $tool_name

		author:        $author_name
		plugin repo:   https://$git.com/$git_username/$tool_name
		license:       https://choosealicense.com/licenses/$license_keyword/


		$tool_name github:   $tool_repo
		$tool_name docs:     $tool_homepage
		$tool_name test:     \`$check_command\`

		After confirmation, the \`$primary_branch\` will be replaced with the generated
		template using the above information. Please ensure all seems correct.
	EOF

	ok="${9:-$(ask_for "Type \`yes\` if you want to continue.")}"
	if [ "yes" != "$ok" ]; then
		printf "Nothing done.\n"
	else
		(
			set -e
			# previous cleanup to ensure we can run this program many times
			git branch template 2>/dev/null || true
			git checkout -f template
			git worktree remove -f out 2>/dev/null || true
			git branch -D out 2>/dev/null || true

			# checkout a new worktree and replace placeholders there
			git worktree add --detach out

			cd "$out"
			git checkout --orphan out
			git rm -rf "$out" >/dev/null
			git read-tree --prefix="$([[ $git == 'github' ]] && echo '' || echo '/')" -u template:template/

			if [ $git == 'github' ]; then
			  user_avatar=$(curl "$user_profile"|grep -o "https://avatars.githubusercontent.com[^\"]*[^\"]"|grep '\?'|head -n 1)
			else
			  user_avatar=$(curl "$user_profile"|grep -o "https://gitlab.com/uploads/-/system/user/avatar/[^\"]*[^\"]"|head -n 1)
			  if [ -z user_avatar ]; then
			    user_avatar=$(curl "$user_profile"|grep -o "https://gitlab.com/secure.gravatar.com/avatar/[^\"]*[^\"]"|head -n 1)
			  fi
			fi 
			# LC_ALL=C grep -obUaP "^\xFF\xD8" 111.jpg
			pext=""
			if [ ! -z "$user_avatar" ]; then
			 curl "$user_avatar" --output avatar
			 ls avatar
			 [ -z $(LC_ALL=en_US.utf8 grep -obUaP "^\xFF\xD8\xFF") ] &&  ( pext="jpg";mv -f avatar "$out"/assets/profile."$pext" )
			 [ -z $(LC_ALL=en_US.utf8 grep -obUaP "^\x89\x50\x4E") ] &&  ( pext="png";mv -f avatar "$out"/assets/profile."$pext" )
			 [ -z $(LC_ALL=en_US.utf8 grep -obUaP "^\x42\x4D\xB6") ] &&  ( pext="bmp";mv -f avatar "$out"/assets/profile."$pext"	)
			 [ -z $(LC_ALL=en_US.utf8 grep -obUaP "^\x3C\x73\x76") ] &&  ( pext="svg";mv -f avatar "$out"/assets/profile."$pext" )
			fi
			if [ -z "$pext"] ; then
			 echo "Not recognized users avatar format. OSI avatar will be used in md files."
			 pext="png"
			 rm -f avatar
			 mv "assets/profile-osi.png" "$out"/assets/profile."$pext"
			else
			 rm -f profile-osi.png
			fi
			# curl $user_avatar --output "$out/assets/profile.png"
			# curl $(curl https://github.com/VadimDor|grep -o "https://avatars.githubusercontent.com[^\"]*[^\"]"|grep '\?'|head -n 1) --output test3.png


			local tmp=$(mktemp)   # Create a temporary file
			# gets removed under a reasonable collection of signals (HUP, INT, QUIT, PIPE and TERM):
			trap "rm -f $tmp; exit 1" 0 1 2 3 13 15 

			shopt -s globstar
			for j in $out/*.md $out/**/*.md ; do
 			  cat "$out/header.html" "$j" >"$tmp"
 			  mv -f "$tmp" "$j"
 			  cat "$out/footer.html" >> "$j"
			done  
			rm -f $out/header.html $out/footer.html

			download_license "$license_keyword" "$out/LICENSE"
			#sed -i '1s;^;TODO: INSERT YOUR NAME & COPYRIGHT YEAR (if applicable to your license)\n;g' "$out/LICENSE"
			sed -i "s/\[yyyy]/$(date +%Y)/g" "$out/LICENSE"
			sed -i "s/\[fullname]/${author_name:-$gitlab_username}/g" "$out/LICENSE"
			sed -i "s/\[name of copyright owner]/${author_name:-$gitlab_username}/g" "$out/LICENSE"
			sed -i "s/\<year\>/$(date +%Y)/g" "$out/LICENSE"
			sed -i "s/\<name of author\>/${author_name:-$gitlab_username}/g" "$out/LICENSE"
			sed -i "s/\<program\>/$(<YOUR TOOL>)/g" "$out/LICENSE"			

			set_placeholder "<YOUR TOOL>" "$tool_name" "$out"
			tool_name_uc=$(echo "$tool_name" | tr '[:lower:]' '[:upper:]')
			set_placeholder "<YOUR TOOL UC>" "$tool_name_uc" "$out"
			tool_name_lc=$(echo "$tool_name" | tr '[:upper:]' '[:lower:]')			
			set_placeholder "<YOUR TOOL LC>" "$tool_name_lc" "$out"
			tool_name_ulc=$(camel_case $tool_name)
			# tool_name_ulc="$(tr '[:lower:]' '[:upper:]' <<< ${tool_name:0:1})${tool_name:1}"		
			set_placeholder "<YOUR TOOL ULC>" "$tool_name_ulc" "$out"
			set_placeholder "<TOOL HOMEPAGE>" "$tool_homepage" "$out"
			set_placeholder "<TOOL REPO>" "$tool_repo" "$out"
			set_placeholder "<TOOL CHECK>" "$check_command" "$out"
			set_placeholder "<YOUR NAME>" "$author_name" "$out"
			# set_placeholder "<YOUR GITHUB USERNAME>" "$github_username" "$out"
			set_placeholder "<YOUR GIT USERNAME>" "$git_username" "$out"			
			set_placeholder "<PRIMARY BRANCH>" "$primary_branch" "$out"
			user_email=$(git config --list|grep 'user.email='| cut -d\=   -f2)
			set_placeholder "<USER EMAIL>" "$user_email" "$out"
			set_placeholder "<PEXT>" "$pext" "$out"
			project_name="$tool_name plugin"
			set_placeholder "<PROJECT NAME>" "$project_name" "$out"
			set_placeholder "<START DATE>" "$project_name" "$(date +%d-%m-%Y)"
			set_placeholder "<GIT TYPE>" "$git" "$out"
			set_placeholder "<USER PROFILE>" "$user_profile" "$out"
		

			git add "$out" 2>/dev/null	
			# remove GitLab or GitHub specific files
			if [ $git == 'github' ]; then
			 git rm -rf "$out/.gitlab" "$out/.gitlab-ci.yml" "$out/README-gitlab.md" 
			else
  			 git rm -rf "$out/.github" "$out/README-github.md" 
			fi 
			# rename GitHub specific files to final filenames
		 	git mv "$out/README-$git.md" "$out/README.md"
			### git mv "$out/contributing-github.md" "$out/contributing.md"
			# special files like README/CHANGELOG/LICENSE/README/LICENSE/AUTHORS
	              if [ "$bats_tests" == "yes" ]; then
		    	printf "Adding BATS submodules for tests.\n"
				git submodule add https://github.com/bats-core/bats-core.git	"test/test_helper/bats"         2>/dev/null
 				git submodule add https://github.com/bats-core/bats-support.git "test/test_helper/bats-support" 2>/dev/null
				git submodule add https://github.com/bats-core/bats-assert.git  "test/test_helper/bats-assert"	2>/dev/null		

			else
				#cat <<-EOF >> ./template/.gitignore
  				#	Dockerfile
				#	docker-compose.yml
				#	test/*
				#EOF
				git rm -rf "$out/test/" "$out/test/*" "$out/Dockerfile" "$out/docker-compose.yml" 
			fi


			#git branch gh-pages

			git commit -m "Generate $tool_name plugin from template."	2>/dev/null		
			cd "$cwd"
			git branch -M out "$primary_branch"
			git worktree remove -f out
			git checkout -f "$primary_branch"

			printf "All done.\n"
			printf "Your %s branch has been reset to an initial commit.\n" "$primary_branch"
			printf "Push to origin/%s with \`git push --force-with-lease\`\n" "$primary_branch"
			# Gitlab??:  printf "You might want to push using \`--force-with-lease\` to origin/%s\n" "$primary_branch"
			
			git push --force-with-lease

			git branch gh-pages
			git checkout gh-pages
			echo "Hello World" > index.html

			git add --all #docs
			git commit -m "Initial commit"
			git push -u origin gh-pages
			# git push origin :gh-pages && 
			# git subtree push --prefix docs origin gh-page
			
			
			printf "Showing pending TODO tags that you might want to review\n"
			git grep -P -n -C 3 "TODO"
		) || cd "$cwd"
	fi
}

# TODO: remove this function after tests:
setup_github() {
	local cwd out tool_name tool_repo check_command author_name github_username tool_homepage ok primary_branch \
	  bats_tests user_email user_profile pext

	cwd="$PWD"
	out="$cwd/out"

	# ask for arguments not given via CLI
	tool_name="${1:-$(ask_for "$HELP_PLUGIN_NAME")}"
	tool_name="${tool_name/asdf-/}"
	check_command="${2:-$(ask_for "$HELP_TOOL_CHECK" "$tool_name --help")}"

	github_username="${3:-$(ask_for "Your GitHub username")}"
	author_name="${4:-$(ask_for "Your name" "$(git config user.name 2>/dev/null)")}"

	tool_repo="${5:-$(ask_for "$HELP_TOOL_REPO" "https://github.com/$github_username/$tool_name")}"
	user_profile="https://github.com/$github_username"
	tool_homepage="${6:-$(ask_for "$HELP_TOOL_HOMEPAGE" "$tool_repo")}"
	license_keyword="${7:-$(ask_license)}"
	license_keyword="$(echo "$license_keyword" | tr '[:upper:]' '[:lower:]')"
	bats_tests="${8:-$(ask_for "Type \`yes\` if you want preinstall environment and samples for BATS tests." "yes" "no")}"

	primary_branch="main"

	cat <<-EOF
		Setting up plugin: $tool_name

		author:        $author_name
		plugin repo:   https://github.com/$github_username/$tool_name
		license:       https://choosealicense.com/licenses/$license_keyword/


		$tool_name github:   $tool_repo
		$tool_name docs:     $tool_homepage
		$tool_name test:     \`$check_command\`

		After confirmation, the \`$primary_branch\` will be replaced with the generated
		template using the above information. Please ensure all seems correct.
	EOF

	ok="${9:-$(ask_for "Type \`yes\` if you want to continue.")}"
	if [ "yes" != "$ok" ]; then
		printf "Nothing done.\n"
	else
		(
			set -e
			# previous cleanup to ensure we can run this program many times
			git branch template 2>/dev/null || true
			git checkout -f template
			git worktree remove -f out 2>/dev/null || true
			git branch -D out 2>/dev/null || true

			# checkout a new worktree and replace placeholders there
			git worktree add --detach out

			cd "$out"
			git checkout --orphan out
			git rm -rf "$out" >/dev/null
			git read-tree --prefix="" -u template:template/


			local user_avatar=curl $user_profile|grep -o "https://avatars.githubusercontent.com[^\"]*[^\"]"|grep '\?'|head -n 1
			# LC_ALL=C grep -obUaP "^\xFF\xD8" 111.jpg
			if [ -z $user_avatar ]; then
			 curl "$user_avatar" --output avatar
			 [ -z $(LC_ALL=C grep -obUaP "^\xFF\xD8\xFF") ] &&  ( pext="jpg";mv -f avatar "$out"/assets/profile."$pext" )
			 [ -z $(LC_ALL=C grep -obUaP "^\x89\x50\x4E") ] &&  ( pext="png";mv -f avatar "$out"/assets/profile."$pext" )
			 [ -z $(LC_ALL=C grep -obUaP "^\x42\x4D\xB6") ] &&  ( pext="bmp";mv -f avatar "$out"/assets/profile."$pext"	)
			 [ -z $(LC_ALL=C grep -obUaP "^\x3C\x73\x76") ] &&  ( pext="svg";mv -f avatar "$out"/assets/profile."$pext" )
			fi
			if [ -z "$pext"] ; then
			 echo "Not recognized users avatar format. OSI avatar will be used in md files."
			 pext="png"
			 mv profile-osi.png "$out"/assets/profile."$pext"
			else
			 rm -f profile-osi.png
			fi
			# curl $user_avatar --output "$out/assets/profile.png"
			# curl $(curl https://github.com/VadimDor|grep -o "https://avatars.githubusercontent.com[^\"]*[^\"]"|grep '\?'|head -n 1) --output test3.png



			download_license "$license_keyword" "$out/LICENSE"
			#sed -i '1s;^;TODO: INSERT YOUR NAME & COPYRIGHT YEAR (if applicable to your license)\n;g' "$out/LICENSE"
			sed -i "s/\[yyyy]/$(date +%Y)/g" "$out/LICENSE"
			sed -i "s/\[fullname]/${author_name:-$gitlab_username}/g" "$out/LICENSE"
			sed -i "s/\[name of copyright owner]/${author_name:-$gitlab_username}/g" "$out/LICENSE"
			sed -i "s/\<year\>/$(date +%Y)/g" "$out/LICENSE"
			sed -i "s/\<name of author\>/${author_name:-$gitlab_username}/g" "$out/LICENSE"
			sed -i "s/\<program\>/$('asf-$tool_name plugin')/g" "$out/LICENSE"			

			set_placeholder "<YOUR TOOL>" "$tool_name" "$out"
			tool_name_uc=$(echo "$tool_name" | tr '[:lower:]' '[:upper:]')
			set_placeholder "<YOUR TOOL UC>" "$tool_name_uc" "$out"
			tool_name_lc=$(echo "$tool_name" | tr '[:upper:]' '[:lower:]')			
			set_placeholder "<YOUR TOOL LC>" "$tool_name_lc" "$out"
			tool_name_ulc=$(camel_case $tool_name)    # "$(tr '[:lower:]' '[:upper:]' <<< ${tool_name:0:1})${tool_name:1}"		
			set_placeholder "<YOUR TOOL ULC>" "$tool_name_ulc" "$out"
			set_placeholder "<TOOL HOMEPAGE>" "$tool_homepage" "$out"
			set_placeholder "<TOOL REPO>" "$tool_repo" "$out"
			set_placeholder "<TOOL CHECK>" "$check_command" "$out"
			set_placeholder "<YOUR NAME>" "$author_name" "$out"
			set_placeholder "<YOUR GITHUB USERNAME>" "$github_username" "$out"
			set_placeholder "<YOUR GIT USERNAME>" "$github_username" "$out"			
			set_placeholder "<PRIMARY BRANCH>" "$primary_branch" "$out"
			user_email=$(git config --list|grep 'user.email='| cut -d\=   -f2)
			set_placeholder "<USER EMAIL>" "$user_email" "$out"
			set_placeholder "<PEXT>" "$pext" "$out"
			project_name="$tool_name plugin"
			set_placeholder "<PROJECT NAME>" "$project_name" "$out"
			set_placeholder "<START DATE>" "$project_name" "$(date +%D)"

			git add "$out"
			# remove GitLab specific files
			git rm -rf "$out/.gitlab" "$out/.gitlab-ci.yml" "$out/README-gitlab.md" "$out/contributing-gitlab.md"
			# rename GitHub specific files to final filenames
			git mv "$out/README-github.md" "$out/README.md"
			git mv "$out/contributing-github.md" "$out/contributing.md"
			# special files like README/CHANGELOG/LICENSE/README/CHANGELOG/LICENSE/AUTHORS
	        if [ "yes" == "$bats_tests" ]; then
		    	printf "Adding BATS submodules for tests.\n"
				git submodule add https://github.com/bats-core/bats-core.git "test/bats"
 				git submodule add https://github.com/bats-core/bats-support.git "test/test_helper/bats-support"
				git submodule add https://github.com/bats-core/bats-assert.git "test/test_helper/bats-assert"			

			else
				#cat <<-EOF >> ./template/.gitignore
  				#	Dockerfile
				#	docker-compose.yml
				#	test/*
				#EOF
				# remove GitLab specific files
				git rm -rf "$out/test/" "$out/test/*" "$out/Dockerfile" "$out/docker-compose.yml" 
			fi
			git commit -m "Generate asdf-$tool_name plugin from template."			
			cd "$cwd"
			git branch -M out "$primary_branch"
			git worktree remove -f out
			git checkout -f "$primary_branch"

			printf "All done.\n"
			printf "Your %s branch has been reset to an initial commit.\n" "$primary_branch"
			printf "Push to origin/%s with \`git push --force-with-lease\`\n" "$primary_branch"

			printf "Review these TODO items:\n"
			git grep -P -n -C 3 "TODO"
		) || cd "$cwd"
	fi
}

# TODO: remove this function after tests:
setup_gitlab() {
	local cwd out tool_name tool_repo check_command author_name github_username gitlab_username tool_homepage ok primary_branch \
	  bats_tests user_email

	cwd="$PWD"
	out="$cwd/out"

	# ask for arguments not given via CLI
	tool_name="${1:-$(ask_for "$HELP_PLUGIN_NAME")}"
	tool_name="${tool_name/asdf-/}"
	check_command="${2:-$(ask_for "$HELP_TOOL_CHECK" "$tool_name --help")}"

	gitlab_username="$(ask_for "Your GitLab username")"
	author_name="${4:-$(ask_for "Your name" "$(git config user.name 2>/dev/null)")}"

	github_username="${3:-$(ask_for "Tool GitHub username")}"
	tool_repo="${5:-$(ask_for "$HELP_TOOL_REPO" "https://github.com/$github_username/$tool_name")}"
	tool_homepage="${6:-$(ask_for "$HELP_TOOL_HOMEPAGE" "$tool_repo")}"
	license_keyword="${7:-$(ask_license)}"
	license_keyword="$(echo "$license_keyword" | tr '[:upper:]' '[:lower:]')"
	bats_tests="${8:-$(ask_for "Type \`yes\` if you want preinstall environment and samples for BATS tests." "yes" "no")}"

	primary_branch="main"

	cat <<-EOF
		Setting up plugin: $tool_name

		author:        $author_name
		plugin repo:   https://gitlab.com/$gitlab_username/$tool_name
		license:       https://choosealicense.com/licenses/$license_keyword/


		$tool_name github:   $tool_repo
		$tool_name docs:     $tool_homepage
		$tool_name test:     \`$check_command\`

		After confirmation, the \`$primary_branch\` will be replaced with the generated
		template using the above information. Please ensure all seems correct.
	EOF

	ok="${9:-$(ask_for "Type \`yes\` if you want to continue.")}"
	if [ "yes" != "$ok" ]; then
		printf "Nothing done.\n"
	else
		(
			set -e
			# previous cleanup to ensure we can run this program many times
			git branch template 2>/dev/null || true
			git checkout -f template
			git worktree remove -f out 2>/dev/null || true
			git branch -D out 2>/dev/null || true

			# checkout a new worktree and replace placeholders there
			git worktree add --detach out

			cd "$out"
			git checkout --orphan out
			git rm -rf "$out" >/dev/null
			git read-tree --prefix=/ -u template:template/

			download_license "$license_keyword" "$out/LICENSE"
			sed -i "s/\[yyyy]/$(date +%Y)/g" "$out/LICENSE"
			sed -i "s/\[fullname]/${author_name:-$gitlab_username}/g" "$out/LICENSE"
			sed -i "s/\[name of copyright owner]/${author_name:-$gitlab_username}/g" "$out/LICENSE"
			sed -i "s/\<year\>/$(date +%Y)/g" "$out/LICENSE"
			sed -i "s/\<name of author\>/${author_name:-$gitlab_username}/g" "$out/LICENSE"
			sed -i "s/\<program\>/$('asf-$tool_name plugin')/g" "$out/LICENSE"				

			set_placeholder "<YOUR TOOL>" "$tool_name" "$out"
			tool_name_uc=$(echo "$tool_name" | tr '[:lower:]' '[:upper:]')
			set_placeholder "<YOUR TOOL UC>" "$tool_name_uc" "$out"
			tool_name_lc=$(echo "$tool_name" | tr '[:upper:]' '[:lower:]')			
			set_placeholder "<YOUR TOOL LC>" "$tool_name_lc" "$out"
			tool_name_ulc="$(tr '[:lower:]' '[:upper:]' <<< ${tool_name:0:1})${tool_name:1}"		
			set_placeholder "<YOUR TOOL ULC>" "$tool_name_ulc" "$out"
			set_placeholder "<TOOL HOMEPAGE>" "$tool_homepage" "$out"
			set_placeholder "<TOOL REPO>" "$tool_repo" "$out"
			set_placeholder "<TOOL CHECK>" "$check_command" "$out"
			set_placeholder "<YOUR NAME>" "$author_name" "$out"
			set_placeholder "<YOUR GITLAB USERNAME>" "$gitlab_username" "$out"
			set_placeholder "<YOUR GIT USERNAME>" "$gitlab_username" "$out"
			set_placeholder "<PRIMARY BRANCH>" "$primary_branch" "$out"
			user_email=$(git config --list|grep 'user.email='| cut -d\=   -f2)
			set_placeholder "<USER EMAIL>" "$user_email" "$out"

			git add "$out"
			# remove GitHub specific files
			git rm -rf "$out/.github" "$out/README-github.md" "$out/contributing-github.md"
			# rename GitLab specific files to final filenames
			git mv "$out/README-gitlab.md" "$out/README.md"
			git mv "$out/contributing-gitlab.md" "$out/contributing.md"
			git submodule add https://github.com/bats-core/bats-core.git "test/bats"
 			git submodule add https://github.com/bats-core/bats-support.git "test/test_helper/bats-support"
			git submodule add https://github.com/bats-core/bats-assert.git "test/test_helper/bats-assert"

	        if [ "yes" == "$bats_tests" ]; then
		    	printf "Adding BATS submodules for tests.\n"
				git submodule add https://github.com/bats-core/bats-core.git "test/bats"
 				git submodule add https://github.com/bats-core/bats-support.git "test/test_helper/bats-support"
				git submodule add https://github.com/bats-core/bats-assert.git "test/test_helper/bats-assert"			
			else
				git rm -rf "$out/test/" "$out/test/*" "$out/Dockerfile" "$out/docker-compose.yml" 
			fi

			git commit -m "Generate $tool_name plugin from template."		
			cd "$cwd"
			git branch -M out "$primary_branch"
			git worktree remove -f out
			git checkout -f "$primary_branch"

			printf "All done.\n"
			printf "Your %s branch has been reset to an initial commit.\n" "$primary_branch"
			printf "You might want to push using \`--force-with-lease\` to origin/%s\n" "$primary_branch"

			printf "Showing pending TODO tags that you might want to review\n"
			git grep -P -n -C 3 "TODO"
		) || cd "$cwd"
	fi
}

case "${1:-}" in
"-h" | "--help" | "help")
	printf "%s\n" "$HELP"
	exit 0
	;;
"--gitlab")
	shift
	setup_git "gitlab" "$@"
	;;
"--github")
	shift
	setup_git "github" "$@"
	;;
*)
	setup_git "github" "$@"
	;;
esac
