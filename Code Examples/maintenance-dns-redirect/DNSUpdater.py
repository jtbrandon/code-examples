# project for changing the DNS records to redirect the maintenance page

from datetime import datetime
from hashlib import sha1
from hmac import new as hmac
import requests
import json
import argparse
import codecs
import re

""" Make a request to the API """
parser = argparse.ArgumentParser(description="Args for Script")
my_group = parser.add_mutually_exclusive_group(required=True)
my_group.add_argument(
    '-d', '--disable', action='store_true', help='disable Maintenance Page')
my_group.add_argument(
    '-e', '--enable', action='store_true', help='enable Maintenance Page')
parser.add_argument(
    '--apikey', type=str, help='Account API KEY')
parser.add_argument(
    '--secretkey', type=str, help='Account SECRET KEY')
parser.add_argument(
    '--cname', type=str, help='CNAME Record Name')
parser.add_argument(
    '--domain', type=str, default="truemark.xyz", help='Domain Name')
parser.add_argument('--sandbox', help="Test on Sandbox account",
                    action="store_true")
args = parser.parse_args()

if args.sandbox == True:
    # Sandbox Base_URL
    base_url = "https://api.sandbox.dnsmadeeasy.com/V2.0/dns/managed/XXXX/records"
else:
    base_url = "https://api.dnsmadeeasy.com/V2.0/dns/managed"
# base_url.old = "https://api.dnsmadeeasy.com/V2.0/dns/managed/6786048/records"
# Sandbox api_key = 'XXXX'
api_key = args.apikey
# Sandbox secret_key = 'XXXX'
secret_key = args.secretkey

# Request function to make API Request calls
def request(url_postfix, request_type="GET", data=None):
    """ Make a request to the API """
    request_url = base_url + '/' + url_postfix
    request_date = datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S GMT")
    request_hmac = hmac(codecs.encode(secret_key), codecs.encode(request_date), sha1).hexdigest()
    # print(request_hmac)
    headers = {
        "x-dnsme-apiKey": api_key,
        "x-dnsme-requestDate": request_date,
        "x-dnsme-hmac": request_hmac,
        "Content-Type": "application/json"
    }

    if request_type == "GET":
        req = requests.get(
            request_url,
            headers=headers
        )
        print(req.text)
    elif request_type == "PUT":
        req = requests.put(
            request_url,
            data=json.dumps(data),
            headers=headers
        )
    elif request_type == "POST":
        req = requests.post(
            request_url,
            data=json.dumps(data),
            headers=headers
        )
    elif request_type == "DELETE":
        req = requests.delete(
            request_url,
            headers=headers
        )

    if req.status_code > 201:
        print(req.status_code)
        if req.status_code == 404:
            raise Exception("%s API endpoint not found" % url_postfix)
        else:
            raise Exception(req.text)

    if len(req.text) > 0:
        return json.loads(req.text)
    else:
        return True


def getDomainID():
    req = request('', "GET", '')
    for domain in req['data']:
        if domain['name'] == args.domain:
            #print("Yes we have found the default domain!")
            #print("ID: {}".format(domain['id']))
            return str(domain['id'])

# Enable the Maintenance Page
def redirect(records):

    # Iterate through each DNS record of the domain
    for record in records['data']:

        # If the DNS record == www, we will store its contents as the Value in a TXT record
        if record['name'] == "www":
            print("Found record(s) that Equal 'www'!")
            print(record)
            newTempRecord = {
                "name": record['name'] + ".new." + str(record['id']),
                "type": "TXT",
                "value": record['value'],
                "ttl": record['ttl']
            }

            # Send TXT version of current record (newTempRecord)
            print("****POST: Creating TXT Backup Record for record {} with value {}".format(record["name"],record['value']))
            request('', "POST", newTempRecord)

            # Updating existing www CNAME records with the value of 'redirects'
            record['value'] = 'redirects'
            print("****PUT: Creating new Redirects CNAME record")
            request(str(record['id']), "PUT", record)

# Disable the Maintenance Page
def restore(records):
    print("RESTORING ARCHIVED RECORD")
    
    # Iterate through each DNS record of the domain
    for record in records['data']:
        if "www.new" in record['name']:
            print("Found the www.new archive TXT record, preparing to restore")

            # Extracting the ID number from the www.new.##### ID
            restoreID = re.findall(r'\d+', str(record['name']))[0]
            
            # Getting all records and then finding the ones that match the ID of the backed up records
            ogRecord = request('', "GET", '')
            for recs in ogRecord['data']:
                # print("Seeing if {} is == to {}".format(recs['id'], restoreID))
                if str(recs['id']) == restoreID:

                    # Stripping off double-quotes from the value
                    recs['value'] = record['value'].replace('"', '')

                    print("PUT: Restoring WWW CNAME Records to original values")
                    request(str(restoreID), "PUT", recs)

                    # Deleting the Temp Archive Backup TXT Records
                    print("DELETE: Deleting www.new archive TXT record")
                    request(str(record['id']), "DELETE", '')
                
            

def main():
    if args.sandbox == False:
        domainID = getDomainID()
        global base_url
        base_url = base_url + '/' + domainID + '/records' 
        print(base_url)
    records = request('',"GET",'')
    if args.enable:
        redirect(records)
    elif args.disable:
        restore(records)
    
if __name__ == "__main__":

    main()

