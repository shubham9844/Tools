#!/bin/bash


file="$1"
while read arg; do
 echo "$arg"
done < "$file" | tee domains.txt

# Check if the directory does not exist
if [ ! -d "apihunting" ]; then
    # Create the directory
    mkdir -p "apihunting"
    echo ""
else
    echo ""
fi
mv domains.txt apihunting/
cd apihunting

if ! which jq &> /dev/null; then
        echo "."
        sudo apt-get update
        sudo apt-get install -y jq
    else
        echo ""
    fi

if [[ ! -e ~/go/bin/subfinder ]]; then
    # If not, create it
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
fi

if [[ ! -e ~/go/bin/anew ]]; then
    # If not, create it
    go install -v github.com/tomnomnom/anew@latest
fi

if [[ ! -e ~/go/bin/httpx ]]; then
    # If not, create it
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
fi

if [[ ! -e ~/go/bin/gau ]]; then
    # If not, create it
    go install github.com/lc/gau/v2/cmd/gau@latest
fi

if [ ! -d "tools" ]; then
    # Create the directory
    mkdir tools
    python3 -m venv tools
fi

if [[ ! -e ./tools/bin/uro ]]; then
    source tools/bin/activate
    pip install uro
    deactivate
fi

if [ ! -d "secretfinder" ]; then
    # Create the directory
    git clone https://github.com/m4ll0k/SecretFinder.git secretfinder
    source tools/bin/activate
    cd secretfinder
    pip install -r requirements.txt
    cd ..
    deactivate

else
    echo ""
fi


~/go/bin/subfinder -dL domains.txt -all -recursive -o subdomains.txt
~/go/bin/httpx -l subdomains.txt > subdomains_alive.txt
cat subdomains_alive.txt | ~/go/bin/gau > all_urls.txt
cat all_urls.txt | uro -o sort_urls.txt
cat sort_urls.txt | grep ".js$" > jsfiles.txt

source tools/bin/activate
cat jsfiles.txt | while read url; do python3 secretfinder/SecretFinder.py -i $url -o cli>> secret.txt; done
cat secret.txt | grep ">"
