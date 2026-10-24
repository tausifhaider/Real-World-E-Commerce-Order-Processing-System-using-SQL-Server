--CUSTOMER TABLE
create table Tbl_Cust(
CID INT PRIMARY KEY,
CustName Nvarchar(100),
Email varchar(100),
CreatedDated DATETIME DEFAULT GETDATE()
)

--ORDER TABLE
CREATE TABLE Tbl_Orders
(
OrderID int primary key,
CID int,
OrderDate  Datetime,
TotalAmount Decimal(18,2),
Status Varchar(20),
Foreign Key (CID) references Tbl_Cust(CID)
)

ALTER TABLE Tbl_Orders ADD CONSTRAINT CK_Order_TotalAmount CHECK(TotalAmount > 0)

--Payment Table
CREATE TABLE Tbl_Pay
(
PID INT primary key,
OrderId  INT,
PaymentDate DateTime,
Amount Decimal(18,2),
PaymentStatus varchar(20),
foreign key(orderId) references Tbl_Orders(OrderID)
)

ALTER TABLE Tbl_Pay ADD CONSTRAINT CK_Pay_Amount CHECK(Amount > 0)

--ORDER STATUS HISTORY TABLE
CREATE TABLE Tbl_OrderHistory
(
 ORHID int PRIMARY KEY IDENTITY(1,1),
 OrderID int,
 OldStatus varchar(20),
 NewStatus varchar(20),
 ChangedDate dateTime default GETDATE()
)

--TASK:-
--->STRONG  'DATA VALIDATION'
--->PROPER ' ERROR HANDLING'
Create proc usp_Createorderwithpayment
(
 @orderID INT,
 @CID INT,
 @TotalAmount decimal(18,2),
 @PaymentAmount decimal(18,2)

)
AS
BEGIN

SET NOCOUNT ON;
BEGIN TRY


BEGIN TRAN

IF (@PaymentAmount > @TotalAmount)
BEGIN
 RAISERROR('Payment amount cannot exceed order amount',16,1);
 RETURN;
END

INSERT_ORDERS_START:

INSERT INTO[dbo].[Tbl_Orders](
OrderID, CID, OrderDate, TotalAmount, Status)
VALUES  (@orderID,  @CID, GETDATE(),@TotalAmount, 'CREATED');


INSERT_ORDERS_END:

INSERT_PAYMENT_START:

INSERT INTO [dbo].[Tbl_Pay](PID, OrderId, PaymentDate, Amount, PaymentStatus)
VALUES(@orderID,@orderID, GETDATE(), @PaymentAmount,'SUCCESS')


INSERT_PAYMENT_END:

UPDATE [dbo].[Tbl_Orders] SET Status ='CONFIRMED' Where OrderID=@orderID

COMMIT TRAN

END TRY
BEGIN CATCH
ROLLBACK TRAN

DECLARE @ErrorMsg Nvarchar(4000) = ERROR_MESSAGE();
RAISERROR(@ErrorMsg, 16,1);



END CATCH

END

--TRIGGER
CREATE TRIGGER Utrg_OrderStatusHistory ON [dbo].[Tbl_Orders]
AFTER UPDATE 
AS 
BEGIN
SET NOCOUNT ON;


INSERT INTO [dbo].[Tbl_OrderHistory]
(
OrderID, OldStatus, NewStatus
)
SELECT d.OrderId, d.Status, i.Status
FROM inserted i JOIN deleted d on i.OrderId=d.OrderId
WHERE i.Status <> d.Status
End


--STORED PROCEDURE-->>MonthlyRevenueReport
CREATE PROC usp_MonthlyRevenueReport
(
@year INT
)
AS 
BEGIN

SELECT DATENAME(MONTH,[PaymentDate]) AS [MONTH],
SUM(Amount) As TotalRev
FROM[dbo].[Tbl_Pay]
WHERE [PaymentStatus] = 'SUCCESS'
GROUP BY DATENAME(MONTH,[PaymentDate]), MONTH([PaymentDate])
ORDER BY MONTH([PaymentDate])

END

EXEC [dbo].[usp_Createorderwithpayment] @OrderId = 105, @CID = 2, @TotalAmount = 400, @PaymentAmount=400

SELECT * FROM Tbl_Orders
SELECT * FROM tbl_pay
SELECT * FROM Tbl_OrderHistory

--MONTHLY REVENUE
[dbo].[usp_MonthlyRevenueReport] @YEAR=2026

--customer who is not palced any order till today
select c.CID, c.[CustName] FROM Tbl_Cust c JOIN Tbl_Orders o
ON c.CID = o.CID

select c.CID, c.[CustName] FROM Tbl_Cust c LEFT JOIN Tbl_Orders o
ON c.CID = o.CID
where o.orderid is null

select c.CID, c.[CustName] FROM Tbl_Cust c 
where NOT EXISTS (
SELECT 1 from Tbl_orders o WHERE o.CID =  C.CID
)

Select * from Tbl_Orders where CID=1 
AND OrderDate >= '2026-10-24'


select OrderId, CID, OrderDate, TotalAmount, Status from Tbl_Orders where CID=1
AND orderDate >= '2026-10-24'

CREATE NONCLUSTERED INDEX IX_Order_CID
ON Tbl_Orders(CID, orderDate)
INCLUDE(TotalAmount, Status)

--TOP 3 CUSTOMER
select top 3 c.cid, c.custname, sum(o. totalamount) totalpurchase
from Tbl_Cust c  join Tbl_Orders O
ON C.CID = O.CID
GROUP BY c.CID, c.CustName
order by totalpurchase desc;
