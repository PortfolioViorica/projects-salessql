---Data Panel: SalesOrderID, OrderDate, SubTotal, StandardCost, OrderQty, LineTotal,UnitPrice,UnitPriceDiscount,ProductName, CategoryName
--Test the basic variables
--Checking the Integrity of the Data
---Calculating Total Due – Order Header
 --check if TotalDue is calculated as sum of SubTotal, TaxAmt, Freight
   
Select SalesOrderID,
      OrderDate,
	  SubTotal,
	  TaxAmt,
	  Freight,
	  TotalDue - (SubTotal+TaxAmt+Freight) as diff
	   
	from sales.SalesOrderHeader
	where TotalDue - (SubTotal+TaxAmt+Freight) <> 0

--Checking the Integrity of the Data
-- Calculating Total Due – Sales Order Details
 --Check if the lineTotal is correct
Select SalesOrderID,
      UnitPrice,
	  UnitPriceDiscount,
	      OrderQty,
	  LineTotal,
	  (UnitPrice-UnitPriceDiscount)*OrderQty as CalcLineTotal,
	  (UnitPrice-UnitPriceDiscount)*OrderQty - LineTotal as diff
	  from sales.SalesOrderDetail
	  where (UnitPrice-UnitPriceDiscount)*OrderQty - LineTotal <> 0

----The analysis of the dataset reveals substantial variations across different columns. 
--These significant differences may indicate diverse patterns, trends, or behaviors within the data.
--Further exploration and understanding of these variations are crucial for making informed decisions. 
--Factors contributing to these differences could include seasonality, market conditions, or specific business strategies. 
--A more in-depth examination of each column will 
--provide valuable insights into the dynamics influencing the observed distinctions and
--help guide strategic decision-making.

--Checking the Integrity of the Data
--Calculating Total Due – Sales Order Details
--Check if the lineTotal is correct 
Select SalesOrderID,
      UnitPrice,
	  UnitPriceDiscount,
	      OrderQty,
	  LineTotal,
	  (UnitPrice-UnitPriceDiscount)*OrderQty as CalcLineTotal,
	  (UnitPrice-UnitPriceDiscount)*OrderQty - LineTotal as diff
from sales.SalesOrderDetail
where (UnitPrice-UnitPriceDiscount)*OrderQty - LineTotal <> 0


--Checking the Integrity of the Data
--Calculating Total Due – Sales Order Details
----Check if the lineTotal is correct discount presentage
Select SalesOrderId
   UnitPrice,
   UnitPriceDiscount,
      OrderQty,
   LineTotal,
   UnitPrice*(1-UnitPriceDiscount)*OrderQty as CalcLineTotal,
   UnitPrice*(1-UnitPriceDiscount)*OrderQty - LineTotal as diff
from sales.SalesOrderDetail
where UnitPrice*(1-UnitPriceDiscount)*OrderQty - LineTotal <> 0
 --After recalculations as a discount percentage, the differences are negligible
 --  (less than 0.007) due to rounding.

	   
---Checking the Integrity of the Data
---Calculating Total Due – Sales Order Header
--Check if the linesTotal is the same as the subTotal
select h.SalesOrderID, h.SubTotal, d.LinesSum,
     h.SubTotal - d.LinesSum as Diff
from Sales.SalesOrderHeader h
   left join  (  select  SalesOrderID,
              sum (UnitPrice*(1-UnitPriceDiscount)* OrderQty) as LinesSum
            from sales.SalesOrderDetail 
			            group by SalesOrderID
						)d
		on d.SalesOrderID = h.SalesOrderID
	where h.SubTotal - d.LinesSum <> 0

--After having applied the conclusions, 
--the differences are negligible (less than 0.007).

 --Checking the Integrity of the Data – Product Table
--check data in product table
select *
from Production.Product
where StandardCost = 0

--There are products without a color.
--    There are 200 rows without costs or list prices. Product ID codes with cost 0: Up to number 679. 
--    From this number onwards, there are values.
--	This can be attributed to the addition of data columns from a specific date onwards.

--Checking the Integrity of the Data –
--Were Products Sold Without Cost?
--Check how many items sold per year without cost
select year (h.OrderDate) as SaleYear,
       count (d.SalesOrderID) as NoCostLines,
	   sum (d.LineTotal) as TotalSalePrice,
	   sum (d.OrderQty)as TotalQtySold
from Sales.SalesOrderDetail d
   left join Sales.SalesOrderHeader h
    on d.SalesOrderID = h.SalesOrderID
   left join Production.Product p
     on d.ProductID = p.ProductID
where p.StandardCost = 0
group by year (h.OrderDate)

-- --It is important to check if there are orders without 
--cost data, as this affects the profitability 
--calculations.
--If there are, check how many, how significant they 
--are and how much effect they have.
--This information will help decide what action to 
--take: Ignore/ Omit/ Update cost data

--Create panel with all the data
create view DetailedProjectPanel as
Select d.SalesOrderID,
h.OrderDate,
d.ProductID,
p.[Name],
p.StandardCost,
d.OrderQty,
d.UnitPrice,
d.UnitPriceDiscount as UnitDiscountPrecent,
d.UnitPrice * (d.UnitPriceDiscount) as UnitDiscountAmount,
d.UnitPrice * (d.UnitPriceDiscount) * d.OrderQty as LineDiscount,
d.LineTotal / d.OrderQty as UnitPriceAfterDiscount,
d.LineTotal / d.OrderQty - p.StandardCost as UnitProfit,
d.LineTotal - p.StandardCost * d.OrderQty as LineProfit,
d.LineTotal
from Sales.SalesOrderDetail d 
left join Sales.SalesOrderHeader h on d.SalesOrderID = h.SalesOrderID
left join Production.Product p on d.ProductID = p.ProductID

SELECT *
FROM DetailedProjectPanel

--1Integrity Check
--When calculating the margin, a significant negative 
--margin was found.
--• The margin calculation was examined and found to 
--be correct.
--• Note that the cost is higher than the sale price.

--2.Assumptions: Check with the business entity
--• Negative profit may be due to an increase in the 
--product cost, but the true, historical costs are not 
--included.
--• It may be due to liquidating inventory even at a loss, 
--a special discount for a customer, a market entry 
--strategy, etc...

----Data Integrity and Quality
-- --Possible Scenarios
--1.Everything is Correct: The low prices are due to a pre-determined strategy,
--and the expected losses have been taken into account.
--2. Recalculate costs: The costs are incorrect,and historical costs were not saved.
--For the purpose of the analysis, calculate the costs using the sale price and a profit ratio.

--Creating a Concentrated Panel
--create concentrate view
 CREATE VIEW 
 MonthConcentrateProjectPanel as
select year (OrderDate) as YearSale,
datepart (quarter, OrderDate) as QuarterSale,
month (OrderDate) as MonthSale,
count (SalesOrderID) as MonthCountSales,
sum (OrderQty) as MonthSumSaleItemQty,
sum (LineTotal) as MonthSumSalesPrice,
sum (LineProfit) as MonthSumProfit,
sum (LineProfit) / sum(OrderQty) as MonthAvgProfit
from DetailedProjectPanel pnl
group by year (OrderDate), datepart (quarter, OrderDate), month (OrderDate)

--1.Examining the Concentrated Panel Data
--The integrity check has uncovered significant negative margins within the dataset.
--It's important to note that the negative interval was previously reviewed with the customer 
--during the creation of the detailed panel, and the data was presumed to be correct at that time. 
--While the negative margins may raise concerns, the prior validation with the customer suggests that 
--these values are intentional or within an acceptable range. However, continuous monitoring 
--and further communication with 
--stakeholders are recommended to ensure ongoing accuracy and to address any 
--potential issues that may arise from the negative margins.".

--  2.Checking abnormal values
--In June 2014, the amount of sales was extremely low 
--compared to the rest of the data.
--There were a lot of sales, but most of the items sold 
--were accessories (tights, tank top, wheels ...), so the 
--prices ranged only between 2.29 - 159

--3.Assumptions: Check with the business entity
--• Any unusual event (political / climate/ medical 
--(corona) / relocation , etc.) may have made them 
--want to liquidate small, cheap goods
--• If this is an exceptional event, consideration must be 
--given to whether to enter the data for analysis or not.
