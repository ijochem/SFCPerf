import SFCManager
import SFC
from copy import copy
import cmd
import time

class Tacker(SFCManager.SFCManager):
    def __init__(self, ip, connection):
        self.ipAddress = ip
        self.connection = connection
        
        self.vars = ". tackerc && "
    
    def deployChain(self, chainName, vnfNames):
        chain = ",".join(vnfNames)

        if self.vnfCheckStatus(vnfNames):
            pass
        else:
            raise Exception("VNFs status error.")

        print "Creating the Chain"
        result = self.runCommand("tacker sfc-create --name "+ chainName+" --chain " + chain)
        print result
        
        return result
    
    def deployClassifier(self, classifier):
        
        print "Deploying Classifier"
        result = self.runCommand("tacker sfc-classifier-create --name " +classifier.name+ " --chain "+ classifier.chain.name+" --match "+classifier.matchRule)
        print result
        
    
        return result
    
    
    def createVNF(self, vnfName, vnfNode, vnfNetwork, vnfDescriptor):
        conn = copy(self.connection)
        conn.connect(self.ipAddress)
        
        
        #criando o descritor
        vnfdFile = open(vnfDescriptor,"r")
        vnfdLines = vnfdFile.readlines()
        i=0
        line = vnfdLines[i]
        while "template_name:" not in line:
            i += 1
            line = vnfdLines[i]
        
        vnfdLines[i] = "template_name: " + vnfName + "-descriptor\n"
        
        i=0
        while "availability_zone:" not in line:
            i += 1
            line = vnfdLines[i]
            
        
        vnfdLines[i] ="      availability_zone: " + vnfNode +"\n"
        
        i=0
        while "network:" not in line:
            i += 1
            line = vnfdLines[i]
        
        vnfdLines[i] ="        network: " + vnfNetwork +"\n"
        
        
        fileName = "/tmp/"+self.randomName()+".yaml"
        fileFinal = open(fileName, "w") 
        fileFinal.write("".join(vnfdLines))
        fileFinal.close()
        
        conn.copy(self.ipAddress, fileName, fileName)
        
        print "Creating VNFd"
        creation = self.runCommand("tacker vnfd-create --vnfd-file %s"%fileName)
        print creation
        
        
        print "Creating VNF"
        creation = self.runCommand("tacker vnf-create --name %s --vnfd-name %s"%(vnfName, vnfName+"-descriptor"))
        print creation
                
        return True


    def vnfCheckStatus(self, vnfNames, ):
        vnfDict = {}
        timeout = time.time() + 60 * 5 # 5 minutes timeout
        result = self.runCommand("tacker vnf-list")
        print "Waiting VNFs to become active"
        print result
        while result != "":
            result = self.runCommand("tacker vnf-list | grep PENDING_CREATE")
            if time.time() > timeout:
                return False
        if self.runCommand("tacker vnf-list | grep ERROR") != "":
            return False
        result = self.runCommand("tacker vnf-list")
        print "Waiting VNFs to start."
        for vnf in vnfNames:
            result = self.runCommand("tacker vnf-list | grep %s | awk '{print $(NF-3)}'"%(vnf))
            ip = result.strip("}").strip("\"")
            vnfDict[vnf] = ip


        print result
        print "VNFs up."
        return True


    def randomName(self, N=5):
        import random
        values = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
        return "".join([random.choice(values) for _ in range(5)])
        

    
    def runCommand(self, cmd):
        conn = copy(self.connection)
        conn.connect(self.ipAddress)
        
        cmd = self.vars + cmd
        
        return conn.command(cmd)
        
def getClass():
    return Tacker