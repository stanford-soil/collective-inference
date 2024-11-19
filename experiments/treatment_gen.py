# Generate the treatments pattern up to 113
treatments = []

for i in range(114):
    slider_direction = "SquirrelsRabbits" if i % 2 == 0 else "RabbitsSquirrels"
    name_suffix = "SR" if i % 2 == 0 else "RS"
    treatment = {
        "name": f"{i}_{name_suffix}_text",
        "factors": {
            "condition": "interactive",
            "opinion": "slider",
            "playerCount": 4,
            "sliderDirection": slider_direction,
            "gameRow": i
        }
    }
    treatments.append(treatment)

for i in range(114):
    slider_direction = "RabbitsSquirrels" if i % 2 == 0 else "SquirrelsRabbits"
    name_suffix = "RS" if i % 2 == 0 else "SR"
    treatment = {
        "name": f"{i}_{name_suffix}_slider",
        "factors": {
            "condition": "slider",
            "opinion": "slider",
            "playerCount": 4,
            "sliderDirection": slider_direction,
            "gameRow": i
        }
    }
    treatments.append(treatment)
# Print the YAML-style output
import yaml
print(yaml.dump({"treatments": treatments}, sort_keys=False))

