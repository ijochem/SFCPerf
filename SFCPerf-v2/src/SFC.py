import json
class SFC:
    def __init__(self, SFCdict):
        if ("Classifier" in SFCdict) and ("Chain" in SFCdict) and ("Management" in SFCdict):  
            pass
        else:
            raise KeyError
        
        self.conexao_params = SFCdict["Management"]["connection"]["params"]
        self.conexao = __import__(SFCdict["Management"]["connection"]["type"]).getClass()(*self.conexao_params)
        ip = SFCdict["Management"]["ip"]
        self.manager = __import__(SFCdict["Management"]["type"]).getClass()(ip, self.conexao)
        
        
        self.chain = Chain(SFCdict["Chain"])
        self.classifier = Classifier(SFCdict["Classifier"], self.chain)
        
        
    def createSFC(self):
        self.chain.createChain(self.manager, self.classifier)


class Chain:
    def __init__(self, chainDict):
        
        self.name = chainDict["name"]
        self.chain = []
        for i in chainDict["chain"]:
            self.chain.append(VNF(i))
        
    def createChain (self, manager, classifier):
        vnfNames = []
        for vnf in self.chain:
            vnf.create(manager)
            vnfNames.append(vnf.name)

        #manager.vnfCheckStatus(vnfNames)

        #manager.vnfActivate(vnfNames)

        manager.deployChain(self.name, vnfNames)
        
        manager.deployClassifier(classifier)


class VNF:
    def __init__(self, vnfDict):
        self.name = vnfDict["name"]
        self.node = vnfDict["node"]
        self.network = vnfDict["network"]
        self.descriptor = vnfDict["descriptor"]
        
    
    def create(self, manager):
        return manager.createVNF(self.name, self.node, self.network, self.descriptor)
    
    
        
class Classifier:
    def __init__(self, ClassifierDict, chain):
        self.name = ClassifierDict["name"]
        self.matchRule = ClassifierDict["matchRule"]
        self.chain = chain
        
        
if __name__ == "__main__":
    dictSFC = {"SFC":{
                      "Classifier":{
                                    "name":"test-classifier-gta",
                                    "matchRule":"source_port=0,dest_port=20000,protocol=6"
                                    },
                      "Chain":{"name":"gta-chain-test",
                               "chain":[
                               {
                                "name":"vnf1-gta",
                                "node":"nova:node-8.gta.ufrj.br",
                                "network": "gta-net-test",
                                "descriptor": "./gta-vnfd.yaml"
                                },
                               {
                                "name":"vnf2-gta",
                                "node":"nova:node-9.gta.ufrj.br",
                                "network": "gta-net-test",
                                "descriptor": "./gta-vnfd.yaml"
                                },
                               {
                                "name":"vnf3-gta",
                                "node":"nova:node-10.gta.ufrj.br",
                                "network": "gta-net-test",
                                "descriptor": "./gta-vnfd.yaml"
                                }
                               ]},
                      "Management":{
                                    "ip":"146.164.69.221",
                                    "type":"Tacker",
                                    "connection":"Mock_SSH",
                                    "connection_params":["gta","opnfv"]                                        
                                    }
                      
                      }
               }
    sfc = SFC(dictSFC["SFC"])
    sfc.createSFC()
    print "JSON"
    print json.dumps(dictSFC)