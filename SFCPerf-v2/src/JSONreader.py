import sys
import json
from Workflow import Workflow

class Reader:
    def __init__(self, file=None):
        self.json_file = file
        if self.json_file == None:
            self.json_file = 'test-file.json'
        self.workflow = json.load(open(self.json_file))
        print "Running experiment: " + self.json_file
    def returnWorkflow(self):
        return Workflow(self.workflow)
    
if __name__ == "__main__":
    if len(sys.argv) > 1:
        r = Reader(str(sys.argv[1]))
    else:
        r = Reader()
    workflow = r.returnWorkflow()
    workflow.run()
