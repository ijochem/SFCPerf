from Test import Test
from copy import copy

class Iperf (Test):
    def __init__(self, src, dst, conexao, *param):
        self.src = src
        self.dst = dst
        self.conexaoSRC = copy(conexao)
        self.conexaoDST = copy(conexao)
        
        if len(param) > 0:
            self.port = param[0]
            self.rate = param[1]
            self.time = param[2]
            self.lenght = param[3]
        else:
            self.rate = 10
            self.time = 10
            self.port = 5000
            self.lenght = 1472
    
    def run(self):
        if self.conexaoDST.connect(self.dst):
            self.conexaoDST.command("killall -9 iperf")
            cmd = " iperf -su -p %s " %(str(self.port),)
            p1 = self.conexaoDST.commandNoBlock(cmd)
        else:
            print "Erro de conexao com o DST"
        
        if self.conexaoSRC.connect(self.src):
            self.conexaoSRC.command("killall -9 iperf")
            cmd ="iperf -c "+ str(self.dst) + " -p "+str(self.port)+" -u -b " + str(self.rate) + " -t " + str(self.time)
            self.result = self.conexaoSRC.command(cmd)
            return self.result
        else:
            print "Erro de conexao com o SRC"
        
    
    def handleResult(self):
        result = Test.handleResult(self).split("Server Report:")[1].strip().split("\n")[0]
        items = result.split(" ")
        valor = float(items[12])
        m = {"K":10**3, "M":10**6, "G":10**9, "b":1}
        mult = items[13][0]
        
        valor = valor*m[mult]
        
        return [valor]
        
        
        
    
def getClass():
    return Iperf
