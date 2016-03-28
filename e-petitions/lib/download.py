import requests
import json
import urlparse
from furl import furl

uri = "http://lda.data.parliament.uk/epetitions.json?_view=ePetitionsListViewer&_pageSize=500&_page=0"

while True:
    params = urlparse.parse_qs(urlparse.urlparse(uri).query)
    page = params['_page'][0]
    print "Processing page {0}".format(page)

    response = requests.get(uri)
    result = json.loads(response.text)["result"]

    with open("data/page-{0}.json".format(page), 'w') as outfile:
        json.dump(result, outfile)

    if result.get("next") is not None:
        uri = furl(result["next"]).add({"_pageSize": "500"}).url
    else:
        print "Done"
        break
