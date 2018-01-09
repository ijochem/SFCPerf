from Visualize import Visualize
from elasticsearch import Elasticsearch
import json
from datetime import datetime

class Kibana (Visualize):
    def __init__(self, *params):
        Visualize.__init__(self, params)
        self.host = params[0]
        self.port = params[1]
        self.index = params[2]
        
        if len(params) > 3:
            self.connectionDict = params[-1]
            
        else:
            self.connectionDict = {}
            
        self.es = Elasticsearch([self.host+":"+str(self.port)],*self.connectionDict)
        
    def putData(self, result):
        resultDict = json.loads(result)
        resultDict["timestamp"] = datetime.now() 
        
        results = resultDict["result"] 
        
        finalRes = True
        
        for r in results:
            resultDict["result"] = r
            partRes = self.es.index(index=self.index, doc_type=resultDict['test'],  body=resultDict)
            finalRes = finalRes and partRes
        
        return finalRes
    
    
def getClass():
    return Kibana 