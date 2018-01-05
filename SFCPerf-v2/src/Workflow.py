import json
import time

class Workflow:
    def __init__(self, jsonWorkflow):
        j = jsonWorkflow
        self.conexao_params = j["connection_params"]
        self.conexao = __import__(j["connection"]).getClass()(*self.conexao_params)
        
        self.testes = []
        for t in j["tests"]:
            src = t["src"]
            dst = t["dst"]
            
            if "output_file" in t:
                output_file = t["output_file"]
            else:
                output_file = None
            
            if "rounds" in t:
                rounds = t["rounds"]
            else:
                rounds = 1
            if "param" in t:
                param = t["param"]
            else:
                param = [] 
            test = __import__(t["test"]).getClass()
            self.testes.append([src, dst, param, test, rounds, output_file])
    
    def run(self):
        for t in self.testes:
            testClass = t[3]
            test = testClass(t[0],t[1],self.conexao, *t[2])
            
            rounds = t[4]
            output_file = t[5]
            
            result = []
            for i in range(rounds):
                r=test.handleResult()
                ####Print da saida do console
                print test.result
                ###############################
                print r
                if type(r) == type([]):
                    result += r
                else:
                    result.append(r)
            self.saveResult(testClass, result, output_file)
            
    def saveResult (self, testClass, result, output_file):
        print testClass.__dict__["__module__"]
        print result
        if output_file:
            f= open(str(output_file), "w")
            f.write(json.dumps({"time":time.time(), "test":testClass.__dict__["__module__"],"result":result}))
            f.close()
            