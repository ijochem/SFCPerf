class Conexao:
    def __init__(self, *params):
        self.params = params
    def connect(self):
        pass
    def commandNoBlock(self, cmd):
        pass
    def command(self, cmd):
        return self.commandNoBlock(cmd).read()