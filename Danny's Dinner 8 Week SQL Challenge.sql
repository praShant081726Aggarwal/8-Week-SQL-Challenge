CREATE SCHEMA dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  
CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  

/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

-- JAI BAJRANGBALI, JAI MAA SARAWATI

select * from sales;

-- 1. What is the total amount each customer spent at the restaurant?
-- Sol: 
SELECT s.customer_id, SUM(m.price) AS total_spent
FROM sales AS s
JOIN menu AS m
ON  s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?
-- Sol:
SELECT customer_id, COUNT(DISTINCT order_date) AS no_of_visit -- Instead of count(order_date) we can also count(customer_id)
FROM sales 
GROUP BY 1;

-- 3. What was the first item from the menu purchased by each customer?
-- Sol:
WITH rank_of_order as 
	( SELECT s.customer_id, m.product_name,
    row_number() OVER( PARTITION BY customer_id ORDER BY order_date ) as order_no 
	FROM sales AS s
	JOIN menu AS m
	ON s.product_id = m.product_id )

SELECT customer_id, product_name
FROM rank_of_order
WHERE order_no = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- Sol:
-- STEP 1 find out most purchased item
SELECT m.product_name, s.product_id, count(s.product_id) as count_orders
			FROM menu AS m 
			JOIN sales AS s
			ON m.product_id = s.product_id
			GROUP BY 1,2
            ORDER BY 3 DESC LIMIT 1;

-- STEP 2 from the most pruchased item find how many times it is purchased by each customer
SELECT sal.customer_id , x.product_name, COUNT(sal.product_id) AS no_of_orders
FROM sales AS sal
JOIN ( SELECT m.product_name, s.product_id, count(s.product_id) AS count_orders
			FROM menu AS m 
			JOIN sales AS s
			ON m.product_id = s.product_id
			GROUP BY 1,2
            ORDER BY 3 DESC LIMIT 1 ) AS x
ON sal.product_id = x.product_id
GROUP BY 1,2;

-- 5. Which item was the most popular for each customer?
WITH CTE as 
	(SELECT m.product_name , s.customer_id, COUNT(s.product_id) as orders,
		rank() over(partition by s.customer_id order by COUNT(s.product_id) DESC) as rnk
		FROM sales as s
		JOIN menu as m
		ON s.product_id = m.product_id
		GROUP BY 1,2)
SELECT product_name , customer_id,  orders
FROM CTE WHERE rnk =1;

-- 6. Which item was purchased first by the customer after they became a member?
-- Sol: Approach 
-- Step 1 First find out all the products which are ordered after becoming member and rank them
-- Step 2 find customer_id and product_name where rank is 1
WITH CTE as 
	(SELECT s.* , mem.join_date,
		rank() over(partition by s.customer_id order by s.order_date ) as rank_order
		FROM sales as s
		JOIN members as mem
		on s.customer_id = mem.customer_id
		where s.order_date >= mem.join_date)
SELECT CTE.customer_id , m.product_name
FROM CTE 
JOIN menu AS m
ON CTE.product_id = m.product_id
WHERE CTE.rank_order = 1
ORDER BY 1;

-- 7. Which item was purchased just before the customer became a member?
-- Step 1 First find out all the products which were ordered before becoming member and rank them
-- Step 2 find customer_id and product_name where rank is 1
WITH CTE as 
	(SELECT s.* , mem.join_date,
		rank() over(partition by s.customer_id order by s.order_date DESC) as rank_order
		FROM sales as s
		JOIN members as mem
		on s.customer_id = mem.customer_id
		where s.order_date < mem.join_date)
SELECT CTE.customer_id , m.product_name
FROM CTE 
JOIN menu AS m
ON CTE.product_id = m.product_id
WHERE CTE.rank_order = 1
ORDER BY 1;
            
-- 8. What is the total items and amount spent for each member before they became a member?
-- Approach 1 ( lengthy ) STEP1 : by using the CTE from Q.7 we can fetch what product are ordered before becoming member
-- STEP2 : JOIN CTE & menu table and fetch customer_id, count total items and sum total spent using aggregate functions
WITH CTE AS
	(SELECT s.* , mem.join_date
		FROM sales as s
		JOIN members as mem
		on s.customer_id = mem.customer_id
		where s.order_date < mem.join_date)
SELECT CTE.customer_id, COUNT(CTE.customer_id) AS total_items, sum(m.price) AS total_spent
FROM CTE
JOIN menu as m
on CTE.product_id = m.product_id
GROUP BY 1 ORDER BY 1;

-- APPROACH 2 (Simple and easy) Jooin all three table, fetch required details and then filter where order_date is less than joining date
SELECT s.customer_id, COUNT(s.product_id) as total_items, SUM(m.price) as total_spent
FROM sales as s 
JOIN menu as m ON s.product_id = m.product_id
JOIN members as mem ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY 1 ORDER BY 1;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- APPROACH 1 : Step-1 --> total spent on each product and make spent double if product is sushi
-- Step-2 --> fetch customer_id and sum of total_spent and multiply with 10 to get points 
WITH CTE AS
	( SELECT s.customer_id, m.product_name, 
		CASE WHEN m.product_name = 'sushi' then SUM(m.price*2)
				else SUM(m.price)
				end as total_amount
		FROM sales AS s
		JOIN menu AS m ON s.product_id = m.product_id
		GROUP BY 1,2)
SELECT customer_id , SUM(total_amount)*10 AS points
FROM CTE 
GROUP BY 1;
-- Approach 2: --> calculate  total points using CASE 
SELECT s.customer_id , 
SUM(CASE WHEN m.product_name = 'sushi' THEN m.price*20
		ELSE m.price*10
        END ) AS Points
FROM sales as s 
JOIN menu as m ON s.product_id = m.product_id
GROUP BY 1;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_id,
SUM( CASE WHEN s.order_date >= mem.join_date AND s.order_date < date_add(mem.join_date, interval 7 day) THEN price*20
		ELSE m.price*10
        END) as Points
FROM sales AS s
JOIN members AS mem ON s.customer_id = mem.customer_id
JOIN menu AS m ON s.product_id = m.product_id
GROUP BY 1 ORDER BY 1;

-- BONUS QUESTIONS

-- Q.1 Join All The Things
-- In this Q. we need to create a table having columns as CUTOMER_ID , ORDER_DATE, PRODUCT_NAME, PRICE, AND MEMBER(yes or no)
-- Sol --> Simply join all the table first and then fetch required columns and the Member Column using case statement when (order_date >= join_date)

SELECT s.customer_id, s.order_date, m.product_name, m.price, 
	CASE WHEN s.order_date >= mem.join_date  THEN 'Y'
	ELSE 'N' END AS member
FROM sales AS s JOIN menu AS m ON s.product_id = m.product_id
LEFT JOIN members AS mem ON s.customer_id = mem.customer_id;

-- Q.2 Rank All The Things
/* Danny also requires further information about the ranking of customer products,but he purposely does not need the ranking for non-member purchases so he expects null ranking values
    for the records when customers are not yet part of the loyalty program. */
-- Sol --> Just need to add rank() function in Q.1
WITH CTE AS 
	(SELECT s.customer_id, s.order_date, m.product_name, m.price, 
			(CASE WHEN s.order_date >= mem.join_date  THEN 'Y'
			ELSE 'N' END) AS members
		FROM sales AS s JOIN menu AS m ON s.product_id = m.product_id
		LEFT JOIN members AS mem ON s.customer_id = mem.customer_id)
SELECT * , 
CASE WHEN members = 'Y' THEN RANK() OVER( PARTITION BY customer_id, members ORDER BY order_date)
End AS ranking
FROM CTE;




