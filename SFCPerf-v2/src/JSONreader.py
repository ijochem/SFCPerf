import json
from Workflow import Workflow

class Reader:
    def __init__(self, file=None):
        self.json_file = file
        if self.json_file == None:
            self.json_file = 'test-file.json'
        self.workflow = json.load(open(self.json_file))
    def returnWorkflow(self):
        return Workflow(self.workflow)
    
if __name__ == "__main__":
    r = Reader()
    workflow = r.returnWorkflow()
    workflow.run()
