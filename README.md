# Project Overview

This project consists of three main components: Terraform configuration, a MongoDB-based `restaurants` service, and a Flask-based `app`. It also includes a GitHub Actions workflow for CICD automation.

## 1. Terraform Configuration

The first step in deploying this project is to execute the Terraform configuration, which sets up the necessary infrastructure on Microsoft Azure. This includes:
- Resource group creation
- MongoDB Atlas deployment
- Virtual network (VNet) and subnets
- Storage account with private endpoint and DNS zone
- Key Vault with private endpoint and DNS zone for secure secrets management
- App Service for hosting the Flask API

### Terraform Variables

The Terraform configuration requires a `terraform.tfvars` file to specify sensitive and environment-specific information. This file is **not** included in the repository for security reasons and must be created and configured manually. It includes sensitive data such as MongoDB public and private keys and deployment-specific details. 

## 2. `restaurants` Service

The `restaurants` service allows you to query restaurant information based on various parameters such as opening hours, closing hours, and restaurant style. The queries are processed through the API endpoint `/rest`. Below are the details on how to format your queries and some example requests.

### Query Parameters

- **`query`**: The main parameter to specify the search criteria. It can include details like opening times, closing times, or restaurant styles.

### Time Format

- **Opening and Closing Times**: Use formats like `HHMM`, `HH:MM`, or `HHMM-HHMM`. The service will parse these formats into valid times.
  - Examples:
    - `opens at 10:00`
    - `closes at 18:30`
    - `between 09:00 and 17:00`

### Restaurant Styles

- **Styles**: Specify the style of the restaurant (e.g., Italian, Steakhouse, Asian, Mediterranean) as part of the query.
  - Examples:
    - `italian`
    - `steakhouse`
    - `asian`

## 3. Adding New Restaurants

To add new restaurants to the database, simply update the `restaurants.json` file located under the `/restaurants` directory. Once a pull request (PR) is submitted and merged, the database will automatically be updated with your new restaurants, provided that the data is in the correct format.

### Steps to Add a New Restaurant:
1. **Locate the `restaurants.json` file**: 
   Navigate to the `/restaurants` directory in the project repository and open the `restaurants.json` file.

2. **Add your restaurant data**: 
   Ensure your new restaurant entries follow the proper format (as outlined below). Each restaurant should include fields such as `name`, `style`, `vegetarian`, `openHour`, and `closeHour`.

3. **Submit a PR**: 
   After adding the new restaurant(s), commit your changes and submit a pull request. The CI/CD pipeline will validate the data and update the MongoDB database if the format is correct.

### Example of Valid `restaurants.json` Format:
```json
[
  {
    "name": "Pasta Delight",
    "style": "Italian",
    "address": "Maskit St 35, Herzliya",
    "vegetarian": "yes",
    "openHour": "10:00",
    "closeHour": "22:00"
  },
  {
    "name": "Sushi Hub",
    "style": "Asian",
    "address": "Maskit St 35, Herzliya",
    "vegetarian": "no",
    "openHour": "12:00",
    "closeHour": "23:00"
  }
]


