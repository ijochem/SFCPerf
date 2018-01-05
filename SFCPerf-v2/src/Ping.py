from Test import Test
class Ping (Test):
    def __init__(self, src, dst, conexao, *param):
        self.src = src
        self.dst = dst
        self.conexao = conexao
        if len(param) > 0:
            self.count = param[0]
        else:
            self.count = 10
    
    def run(self):
        self.conexao.connect(self.src)
        cmd = "ping -c "+str(self.count)+" "+ str(self.dst)
        return self.conexao.command(cmd)
    
    def handleResult(self):
        self.result = self.run()
        linhas = self.result.split("\n")
        
        times = []
        
        for linha in linhas:
            if "time=" in linha:
                t = float(linha.split("time=")[1].split(" ")[0])
                times.append(t)
        
        return times  
    
def getClass():
    return Ping
