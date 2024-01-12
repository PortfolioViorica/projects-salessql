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

--Generate Analysis results
--Monthly Profit Ranking Query
--Month ranking Profit
Select YearSale,
MonthSale,
MonthSumProfit,
rank () over (partition by YearSale order by MonthSumProfit desc) as MonthRank
from MonthConcentrateProjectPanel
order by MonthRank, MonthSumProfit desc

--The historical data analysis reveals a consistent trend where the month of November stands out 
--as a relatively profitable period over the years. This suggests that businesses or activities associated 
--with this particular month tend to exhibit strong financial performance. The observed pattern may be 
--attributed to various factors such as seasonal trends, 
--promotions, or increased consumer spending during this time, emphasizing the significance 
--of November in contributing to overall profitability.

--Monthly Sales Ranking
Select YearSale,
MonthSale,
MonthSumSalesPrice,
rank () over (partition by YearSale order by MonthSumSalesPrice desc) as MonthRank
from MonthConcentrateProjectPanel
order by MonthRank, MonthSumProfit desc

--   While the monthly ranking did not reveal distinct patterns, it is noteworthy that June and July 
--consistently emerge as months with relatively high revenues across multiple years. 
--This observation suggests that businesses or activities associated with these summer months tend to perform well financially. 
--Further investigation into specific factors influencing performance during June and July 
--could provide insights into the observed revenue patterns.


--Quartely Margin Ranking
--Quarter ranking sale price
Select YearSale,
       QuarterSale,
	   sum (MonthSumProfit) as QuartSumProfit,
	   rank () over (partition by YearSale order by sum (MonthSumProfit)desc) as
	   QuartRank
from MonthConcentrateProjectPanel

group by YearSale, QuarterSale
order by QuartRank, QuartSumProfit desc

--  The comprehensive analysis of financial data spanning multiple years reveals that 
--the last quarter consistently stands out as the most profitable period. 
--Additionally, the first quarter demonstrates a notable level of profitability. 
--These findings suggest potential seasonal trends or business patterns, 
--emphasizing the significance of year-end performance and the relatively strong start to each fiscal year.

--Quarterly Sales Ranking
Select YearSale,
       QuarterSale,
	   sum (MonthSumSalesPrice) as QuartSumPrice,
	   rank () over (partition by YearSale order by sum (MonthSumSalesPrice)desc) as
	   QuartRank
from MonthConcentrateProjectPanel

group by YearSale, QuarterSale
order by QuartRank, QuartSumPrice desc

--  The analysis of the sales data indicates that the third quarter 
--consistently exhibits relatively high revenues compared to other quarters. 
--This finding suggests that businesses or activities generating revenue in 
--this dataset tend to perform well during the third quarter.

--Which products are top sallers
--The most sold and profit Product Category  
SELECT 
   top 10 pnl.ProductID, 
      p.[Name] as Name, 
	  --pc.[Name] As Category_Name,
	SUM(OrderQty) AS Total_quantity_sold,
    RANK() over (ORDER BY SUM(OrderQty) asc) AS Ranking,
	sum(LineProfit) As Profit_of_Products,
	RANK() over (ORDER BY SUM(LineProfit) asc) AS Ranking

	FROM DetailedProjectPanel pnl LEFT JOIN Production.Product p 
	 on pnl.ProductID = p.ProductID
	 LEFT JOIN Production.ProductCategory pc on pc. [Name] = p. [Name]
	 GROUP BY pnl.ProductID, p.[Name], pc.[name]
ORDER BY SUM(OrderQty), sum(LineProfit)
  --
SELECT *
FROM DetailedProjectPanel

---

--The analysis of sales data indicates a notable trend wherein accessories consistently outperform 
--clothes in terms of sales. It appears that customers show a stronger preference 
--for accessories, leading to higher sales figures for this category. 
--The relatively lower sales of clothes may suggest potential areas for improvement or 
--targeted marketing strategies to boost sales in this segment. 
--Understanding customer preferences and adapting product offerings accordingly could be 
--crucial for optimizing overall sales and maximizing profitability.

---Creating a data panel
drop table if exists #Panel_Revenue_Profit
select  d.SalesOrderID, h.OrderDate, d.ProductID, p.StandardCost, d.OrderQty, d.LineTotal,
		d.LineTotal - (p.StandardCost * d.OrderQty) as Profit, 
		d.UnitPrice, d.UnitPriceDiscount as UnitDiscountPercent, d.UnitPrice*UnitPriceDiscount as UnitDiscountAmount,
		c.[Name] as CategoryName, p.[Name] as ProductName
into #Panel_Revenue_Profit
from  Sales.SalesOrderHeader h
 left join Sales.SalesOrderDetail d
 on h.SalesOrderID = d.SalesOrderID
  left join Production.Product p
   on d.ProductID = p.ProductID
   left join Production.ProductSubcategory s
     on p.ProductSubcategoryID = s.ProductSubcategoryID
	   left join Production.ProductCategory c
	     on s.ProductCategoryID = c.ProductCategoryID
	
select *
from #Panel_Revenue_Profit


select  CategoryName, 
		SUM ( OrderQty) as NoOfItemsSold,
		RANK () over (order by SUM ( OrderQty) desc) SalesRank, 
		FORMAT(SUM (LineTotal) ,'#,###') TotalRevenue,
		RANK () over (order by SUM (LineTotal) desc) RevenueRank,
		FORMAT(SUM (Profit), '#,###') as LineProfit,
		RANK () over (order by SUM (Profit) desc) ProfitRank,
		FORMAT(SUM (UnitDiscountAmount),'#,###') as AmountDiscount,
		RANK () over (order by SUM (UnitDiscountAmount) desc) AmountDiscountRank,
		AVG (UnitDiscountPercent) as AvgDiscount
 from #Panel_Revenue_Profit
 group by CategoryName

 --Category Bikes is the most sold from all categories and has the highest revenue, profit and amount of discount.

--Annual Sales Query
--By comparing the incomplete data in 2011 and 2014 with corresponding months in
--previous and subsequent years, you can gain a better 
--understanding of the context and potential factors influencing the observed patterns.

SELECT 
    YEAR(OrderDate) AS YearSale,
    Count(SalesOrderID) AS YearCountSales,
	SUM(OrderQty) AS SumYearSaleItemQty,
	Sum(LineTotal) AS SumYearSalesPrice,
    SUM(UnitProfit) AS SumYearProfit
FROM DetailedProjectPanel pnl
GROUP BY YEAR(OrderDate)
ORDER BY YearSale

--The comparative analysis between 2013 and 2012 indicates a more successful 
--performance in 2013. Key indicators demonstrate substantial increases, with a notable 50% growth 
--in the quantity of items sold, a significant 76% increase in the amount of sales, 
--and a commendable 20% rise in profits. These positive trends across multiple metrics suggest 
--that the business or activities in 2013 experienced robust growth and 
--financial success compared to the preceding year, showcasing a positive 
--trajectory in overall performance.