#!/bin/bash

# 拉文件
if [ ! -d rule ]; then
	git init
	git remote add origin https://github.com/blackmatrix7/ios_rule_script.git
	git config core.sparsecheckout true
	echo "rule/Clash" >>.git/info/sparse-checkout
	git pull --depth 1 origin master
	rm -rf .git
fi
# 移动文件/目录到同一文件夹
list=($(find ./rule/Clash/ | awk -F '/' '{print $5}' | sed '/^$/d' | grep -v '\.' | sort -u))
for ((i = 0; i < ${#list[@]}; i++)); do
	path=$(find ./rule/Clash/ -name ${list[i]})
	mv $path ./rule/Clash/
done

list=($(ls ./rule/Clash/))
for ((i = 0; i < ${#list[@]}; i++)); do
	if [ -z "$(ls ./rule/Clash/${list[i]} | grep '.yaml')" ]; then
		directory=($(ls ./rule/Clash/${list[i]}))
		for ((x = 0; x < ${#directory[@]}; x++)); do
			mv ./rule/Clash/${list[i]}/${directory[x]} ./rule/Clash/${directory[x]}
		done
		rm -r ./rule/Clash/${list[i]}
	fi
done

list=($(ls ./rule/Clash/))
for ((i = 0; i < ${#list[@]}; i++)); do
	if [ -f "./rule/Clash/${list[i]}/${list[i]}_Classical.yaml" ]; then
		mv ./rule/Clash/${list[i]}/${list[i]}_Classical.yaml ./rule/Clash/${list[i]}/${list[i]}.yaml
	fi
done

# 处理文件
list=($(ls ./rule/Clash/))
for ((i = 0; i < ${#list[@]}; i++)); do
	mkdir -p ${list[i]}
	# 归类
	# android package
	if [ -n "$(cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep PROCESS | grep -v '\.exe' | grep -v '/' | grep '\.')" ]; then
		cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' |  grep PROCESS | grep -v '\.exe' | grep -v '/' | grep '\.' | sed 's/  - PROCESS-NAME,//g' > ${list[i]}/package.json
	fi
	# process name
	if [ -n "$(cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep PROCESS | grep -v '/' | grep -v '\.')" ]; then
		cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep -v '#' | grep PROCESS | grep -v '/' | grep -v '\.' | sed 's/  - PROCESS-NAME,//g' > ${list[i]}/process.json
	fi
	if [ -n "$(cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep PROCESS |  grep '\.exe')" ]; then
		cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep -v '#' | grep PROCESS |  grep '\.exe' | sed 's/  - PROCESS-NAME,//g' >> ${list[i]}/process.json
	fi
	# domain
	if [ -n "$(cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep '\- DOMAIN-SUFFIX,')" ]; then
		cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep '\- DOMAIN-SUFFIX,' | sed 's/  - DOMAIN-SUFFIX,//g' > ${list[i]}/domain.json
		cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep '\- DOMAIN-SUFFIX,' | sed 's/  - DOMAIN-SUFFIX,/./g' > ${list[i]}/suffix.json
	fi
	if [ -n "$(cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep '\- DOMAIN,')" ]; then
		cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep '\- DOMAIN,' | sed 's/  - DOMAIN,//g' >> ${list[i]}/domain.json
	fi
	if [ -n "$(cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep '\- DOMAIN-KEYWORD,')" ]; then
		cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep '\- DOMAIN-KEYWORD,' | sed 's/  - DOMAIN-KEYWORD,//g' > ${list[i]}/keyword.json
	fi
	# ipcidr
	if [ -n "$(cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep '\- IP-CIDR')" ]; then
		cat ./rule/Clash/${list[i]}/${list[i]}.yaml | grep -v '#' | grep '\- IP-CIDR' | sed 's/  - IP-CIDR,//g' | sed 's/  - IP-CIDR6,//g' > ${list[i]}/ipcidr.json
	fi
	# 转成json格式
	# android package
	if [ -f "${list[i]}/package.json" ]; then
		sed -i 's/^/        "/g' ${list[i]}/package.json
		sed -i 's/$/",/g' ${list[i]}/package.json
		sed -i '1s/^/      "package_name": [\n/g' ${list[i]}/package.json
		sed -i '$ s/,$/\n      ],/g' ${list[i]}/package.json
	fi
	# process name
	if [ -f "${list[i]}/process.json" ]; then
		sed -i 's/^/        "/g' ${list[i]}/process.json
		sed -i 's/$/",/g' ${list[i]}/process.json
		sed -i '1s/^/      "process_name": [\n/g' ${list[i]}/process.json
		sed -i '$ s/,$/\n      ],/g' ${list[i]}/process.json
	fi
	# domain
	if [ -f "${list[i]}/domain.json" ]; then
		sed -i 's/^/        "/g' ${list[i]}/domain.json
		sed -i 's/$/",/g' ${list[i]}/domain.json
		sed -i '1s/^/      "domain": [\n/g' ${list[i]}/domain.json
		sed -i '$ s/,$/\n      ],/g' ${list[i]}/domain.json
	fi
	if [ -f "${list[i]}/suffix.json" ]; then
		sed -i 's/^/        "/g' ${list[i]}/suffix.json
		sed -i 's/$/",/g' ${list[i]}/suffix.json
		sed -i '1s/^/      "domain_suffix": [\n/g' ${list[i]}/suffix.json
		sed -i '$ s/,$/\n      ],/g' ${list[i]}/suffix.json
	fi
	if [ -f "${list[i]}/keyword.json" ]; then
		sed -i 's/^/        "/g' ${list[i]}/keyword.json
		sed -i 's/$/",/g' ${list[i]}/keyword.json
		sed -i '1s/^/      "domain_keyword": [\n/g' ${list[i]}/keyword.json
		sed -i '$ s/,$/\n      ],/g' ${list[i]}/keyword.json
	fi
	# ipcidr
	if [ -f "${list[i]}/ipcidr.json" ]; then
		sed -i 's/^/        "/g' ${list[i]}/ipcidr.json
		sed -i 's/$/",/g' ${list[i]}/ipcidr.json
		sed -i '1s/^/      "ip_cidr": [\n/g' ${list[i]}/ipcidr.json
		sed -i '$ s/,$/\n      ],/g' ${list[i]}/ipcidr.json
	fi
	# 合并文件
	if [ -f "${list[i]}/package.json" -a -f "${list[i]}/process.json" ]; then
		mv ${list[i]}/package.json ${list[i]}.json
		sed -i '$ s/,$/\n    },\n    {/g' ${list[i]}.json
		cat ${list[i]}/process.json >> ${list[i]}.json
		rm ${list[i]}/process.json
	elif [ -f "${list[i]}/package.json" ]; then
		mv ${list[i]}/package.json ${list[i]}.json
	elif [ -f "${list[i]}/process.json" ]; then
		mv ${list[i]}/process.json ${list[i]}.json
	fi

	if [ "$(ls ${list[i]})" = "" ]; then
		sed -i '1s/^/{\n  "version": 1,\n  "rules": [\n    {\n/g' ${list[i]}.json
	elif [ -f "${list[i]}.json" ]; then
		sed -i '1s/^/{\n  "version": 1,\n  "rules": [\n    {\n/g' ${list[i]}.json
		sed -i '$ s/,$/\n    },\n    {/g' ${list[i]}.json
		cat ${list[i]}/* >> ${list[i]}.json
	else
		cat ${list[i]}/* >> ${list[i]}.json
		sed -i '1s/^/{\n  "version": 1,\n  "rules": [\n    {\n/g' ${list[i]}.json
	fi
	sed -i '$ s/,$/\n    }\n  ]\n}/g' ${list[i]}.json
	rm -r ${list[i]}
	./sing-box rule-set compile ${list[i]}.json -o ${list[i]}.srs
done
