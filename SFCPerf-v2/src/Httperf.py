from Test import Test
from copy import copy


class Httperf(Test):
    def __init__(self, src, dst, conexao, *param):
        self.src = src
        self.dst = dst
        self.conexaoSRC = copy(conexao)
        self.conexaoDST = copy(conexao)

        if len(param) > 0:
            self.port = param[0]
            self.conns = param[1]
            self.httpv = param[2]
        else:
            self.port = 5000
            self.conns = 3000
            self.httpv = "1.1"

    def run(self):
        if self.conexaoDST.connect(self.dst):
            self.conexaoDST.command("killall -9 screen")
            cmd = " \"screen -d -m python -m SimpleHTTPServer %s\"" % (str(self.port),)
            p1 = self.conexaoDST.commandNoBlock(cmd)
        else:
            print "Erro de conexao com o DST"

        if self.conexaoSRC.connect(self.src):
            self.conexaoSRC.command("killall -9 httperf")
            cmd = "httperf --server " + str(self.dst) + " --port " + str(self.port) + " --num-conns=" + str(self.conns)\
                  + " --http-version=" + self.httpv
            self.result = self.conexaoSRC.command(cmd)
            self.conexaoDST.command("killall -9 screen")
            return self.result
        else:
            print "Erro de conexao com o SRC"

    def handleResult(self):
        result = Test.handleResult(self).split("Connection rate:")[1].strip().split("\n")[0]
        valor = float(result.split(" ")[0])
        return [valor]


def getClass():
    return Httperf
