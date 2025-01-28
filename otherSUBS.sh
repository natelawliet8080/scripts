#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <domains_file>"
    exit 1
fi
domains_file="$1"
output_file="subs-others"
> "$output_file"
while IFS= read -r domain; do
    if [ -z "$domain" ] || [[ "$domain" =~ ^# ]]; then
        continue
    fi
    echo "Processing $domain..."
    echo "crt.sh (wildcard subdomains):" >> "$output_file"
    curl -s "https://crt.sh/?q=%25.${domain}&output=json" | jq -r '.[].name_value | sub("\\*\\."; "")' | sort -u >> "$output_file"
    echo "crt.sh (exact domain):" >> "$output_file"
    curl -s "https://crt.sh/?q=${domain}&output=json" | jq -r '.[].name_value' | grep -Po '([a-zA-Z0-9-]+\.[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+)$' >> "$output_file"
    echo "Certspotter API:" >> "$output_file"
    curl -s "https://api.certspotter.com/v1/issuances?domain=${domain}&include_subdomains=true&expand=dns_names" | jq -r '.[].dns_names[]' | grep -Po '([a-zA-Z0-9-]+\.[a-zA-Z0-9-]+\.[a-zA-Z]{2,})' | sort -u >> "$output_file"
    echo "HackerTarget:" >> "$output_file"
    curl -s "https://api.hackertarget.com/hostsearch/?q=${domain}" >> "$output_file"
    echo "AlienVault:" >> "$output_file"
    curl -s "https://otx.alienvault.com/api/v1/indicators/domain/${domain}/url_list?limit=100&page=1" | grep -o '"hostname": *"[^"]*' | sed 's/"hostname": "//' | sort -u >> "$output_file"
    echo "Wayback Machine:" >> "$output_file"
    curl -s "http://web.archive.org/cdx/search/cdx?url=*.${domain}/*&output=text&fl=original&collapse=urlkey" | sed -e 's_https*://__' -e 's/\/.*//' | sort -u >> "$output_file"
    echo "Subdomain Center:" >> "$output_file"
    curl -s "https://api.subdomain.center/?domain=${domain}" | jq -r '.[]' | sort -u >> "$output_file"
    echo -e "\n\n" >> "$output_file"
done < "$domains_file"
echo "Subdomain enumeration complete. Results saved in $output_file"
