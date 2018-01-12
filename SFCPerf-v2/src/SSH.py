import os
from Conexao import Conexao
from threading import Thread

class SSH (Conexao):
    def __init__(self, user, password):
        Conexao.__init__(self, user, password)
        self.user = user
        self.password = password
        
    
    def connect(self, host):
        self.connectString = "sshpass -p %s ssh -o StrictHostKeyChecking=no %s@%s "%(self.password, self.user, host)
        a = os.popen(self.connectString + " echo hello").read()
        return a.find("hello")>-1
    
    def commandNoBlock(self, cmd):
        t= Thread(target=self.command, args=[cmd])
        t.start()
        return t  
    
    def command(self, cmd):
        return os.popen(self.connectString + "\"" + cmd + "\"").read()
    
    def copy(self, host, srcFile, dstFile):
        copyString = "sshpass -p %s scp -o StrictHostKeyChecking=no %s %s@%s:%s"%(self.password, srcFile, self.user, host, dstFile)
        a = os.popen(copyString)
        
        return a.read()
    

def getClass():
    return SSH