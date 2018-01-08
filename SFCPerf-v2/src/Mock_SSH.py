import os
from Conexao import Conexao

class Mock_SSH (Conexao):
    def __init__(self, user, password):
        Conexao.__init__(self, user, password)
        self.user = user
        self.password = password
        
    
    def connect(self, host):
        self.connectString = "sshpass -p %s ssh -o StrictHostKeyChecking=no %s@%s "%(self.password, self.user, host)
        #a = os.popen(self.connectString + " echo hello").read()
        print self.connectString
        return True
    
    def commandNoBlock(self, cmd):
        print self.connectString + cmd
        return None
    
    def command(self, cmd):
        return self.commandNoBlock(cmd)
    
    def copy(self, host, srcFile, dstFile):
        copyString = "sshpass -p %s scp -o StrictHostKeyChecking=no %s %s@%s:%s"%(self.password, srcFile, self.user, host, dstFile)
        print copyString
        
        return copyString   

def getClass():
    return Mock_SSH