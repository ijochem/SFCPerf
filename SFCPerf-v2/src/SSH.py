import os
from Conexao import Conexao

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
        return os.popen(cmd)
    

def getClass():
    return SSH