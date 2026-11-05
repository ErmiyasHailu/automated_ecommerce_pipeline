"""import json
import pandas
with open("data_products.json","r") as file:
    data=json.load(file)
print("====products===")
print(type(data))
print(len(data))
print(data[0].keys())

with open("data_carts.json","r") as file:
    data=json.load(file)
print("====carts===")
print(type(data))
print(len(data))
print(data[0].keys())

with open("data_users.json","r") as file:
    data=json.load(file)
print("===Users===")
print(type(data)) ## retrun records
print(len(data))
print(data[0].keys())"""


import json

files = [
    "data/raw/data_products.json",
    "data/raw/data_carts.json",
    "data/raw/data_users.json"
]

for filename in files:

    with open(filename, "r") as file:
        data = json.load(file)

    print(f"\n===== {filename} =====")
    print("Data type:", type(data))
    print("Number of records:", len(data))
    print("Keys:", data[0].keys())


