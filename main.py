import random
import json


def createData():
    return [round(random.uniform(20, 25)) for _ in range(10)]


def createFile(data):
    res = json.dumps(data, separators=(",", ":"))
    print(res)


data = createData()
createFile(data)