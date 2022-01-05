#!/bin/bash

if [ -z "$1" ]
then
	rep="."
else
    rep="$1"
fi	

if [ -z "$CI_PAGES_URL" ]
then
  export CI_PAGES_URL="."
fi

if [ -z "$URL_PROGRESSION" ]
then
  export URL_PROGRESSION="https://progression.dti.crosemont.quebec"
fi

vérifier () {
	err=$(python3 -m progression_qc $1 2>&1 >/dev/null)
	if [ $? -eq 1 ]
	then
		echo "* $(get_titre $1) :"
		echo "#+begin_example"
		echo $err
		echo "#+end_example"
		return 1
	else
		return 0
	fi
}

créer_liens () {
	uuid=$(get_uuid $1)
	if [ -z "$uuid" ]
	then
		uuid=$(dirname $1|md5sum|head -c 32)
	fi

	mkdir /tmp/q/$uuid
	cp -r $(dirname $1)/* /tmp/q/$uuid
	   
    URL=$CI_PAGES_URL/$uuid/info.yml
	URL_B64=$(echo -n $URL | base64 -w0 | sed "s/=*$//")


    titre=$(get_titre $1)
	if [ $(get_niveau $1) = "défi" ]
	then
		niveau="🌶"
	else
		niveau=""
	fi
	
    #bash -c "printf '*%.0s' {1..$(( $2 + 1 ))}"
	echo "@@html:<details><summary>@@"
	echo "[[$URL_PROGRESSION/?uri=$URL_B64#/question][$titre]] $niveau"
	echo "@@html:</summary>@@"
	echo " {{{voir($URL)}}}"
	echo " #+begin_quote"
	get_description $1
	echo " #+end_quote"
	echo "@@html:</details>@@"
	echo
}

get_titre () {
	titre=$(grep -i titre: $1|sed 's/titre:[ \t]*\(.*\)$/\1/I')
	[ -n "$titre" ] && echo $titre || echo $(basename $1)
}

get_niveau () {
	grep -i niveau: $1|sed 's/niveau:[ \t]*\(.*\)$/\1/I'
}

get_description () {
	grep -i description: $1|sed 's/description:[ \t]*\(.*\)$/\1/I'
}

get_uuid () {
	grep -i uuid: $1|sed 's/uuid:[ \t]*\(.*\)$/\1/I'
}

chercher () {
	if [ -f $1/contenu.txt ] && [ -n "$(get_titre $1/contenu.txt)" ]
	then
		bash -c "printf '*%.0s' {1..$2}"
		echo " $(get_titre $1/contenu.txt)"
	else	
		find $1 -mindepth 2 -name info.yml -exec bash -c "printf '*%.0s' {1..$2} && echo ' ' $(basename $1)" \; -quit || return
    fi			   

	for f in $(find $1 -mindepth 1 -maxdepth 1 -type d|sort)
	do
		bash -c "chercher $f $(( $2 + 1 ))" \;
	done
		
	find $1 -maxdepth 1 -name info.yml -exec bash -c "vérifier {} && créer_liens {} $2" \;
}

entête () {
	echo "#+setupfile: https://plafrance.pages.dti.crosemont.quebec/org-html-themes/org/theme-readtheorg.setup"
	echo "#+title: $2"
	echo "#+OPTIONS: toc:3"
	echo "#+OPTIONS: num:3"
	echo '#+MACRO: voir @@html:<div class="urlcache"><a class="urlvisible" onclick=parentNode.classList.toggle("urlcache");>&#128279;</a><pre>src=$1</pre><a class="likeAButton copy" onclick=navigator.clipboard.writeText("src=$1");>📋</a></div>@@'
	echo '@@html:<link rel=stylesheet type="text/css" href="./questions.css"/>@@'
}

export -f créer_liens
export -f vérifier
export -f get_titre
export -f get_niveau
export -f get_description
export -f get_uuid
export -f chercher
export -f entête

dir="$1"

mkdir /tmp/q /tmp/public
cp $dir/public/questions.css /tmp/public

entête "$dir/questions" "Questions de tests" > /tmp/public/questions_de_tests.org
chercher "$dir/questions" 1 >> /tmp/public/questions_de_tests.org
emacs --batch --load $HOME/.emacs.el --load $dir/publish.el --funcall org-publish-all
mv /tmp/q/* /tmp/public/
rm -rf /tmp/q
