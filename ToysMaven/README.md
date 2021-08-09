# Exploratory Data Analysis - Maven Toys #


## Introduction ##
Maven Toys is a fictitious chain of toy stores in Mexico. This dataset includes information about products, stores, daily sales transactions, and current inventory levels at each location. 

## Source ##
The data source is [Maven Analytics]( https://www.mavenanalytics.io/data-playground)

## Objective ##
The objective of this project is to answer the following questions:
-	What was the total sales by city?
-	What was the total sales by category?
-	How much money is tied up in inventory at the toy stores?
-	What were the top 5 products sold? 
-	Which product categories drive the biggest profits?
-	How was the distribution of sales of the different categories over the different months? Is there any seasonality?

## Data Dictionary ##

### **_invetory table_** ###

Store_ID:	Store ID

Product_ID:	Product ID

Stock_On_Hand:	Stock quantity of the product in the store (inventory)



### **_products table_** ###


Product_ID:	Product ID

Product_Name:	Product name

Product_Category:	Product Category

Product_Cost:	Product cost ($USD)

Product_Price:	Product retail price ($USD)





### **_stores table_** ###

Store_ID:	Store ID

Store_Name:	Store name

Store_City:	City in Mexico where the store is located

Store_Location:	Location in the city where the store is located

Store_Open_Date:	Date when the store was opened



### **_sales table_** ###

Sale_ID:	Sale ID

Date:	Date of the transaction

Store_ID:	Store ID

Product_ID:	Product ID

Units:	Units sold




