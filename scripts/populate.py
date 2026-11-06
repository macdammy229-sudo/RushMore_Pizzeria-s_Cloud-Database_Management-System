import os
import random
from datetime import datetime, timedelta

import psycopg2
from dotenv import load_dotenv
from faker import Faker
from psycopg2 import sql
from psycopg2.extras import execute_batch

load_dotenv()

# Fixed seeds and date bounds make generated records repeatable across clean runs.
SEED = 20261106
random.seed(SEED)
Faker.seed(SEED)
fake = Faker("en_US")
DATA_AS_OF = datetime(2025, 12, 31, 23, 59, 59)

STORES = 4
INGREDIENTS = 45
CUSTOMERS = 6_500
ORDERS = 30_000
TARGET_ORDER_ITEMS = 75_000

MENU_DATA = [
    ("Large Pepperoni Pizza", "Pizza", "Large", 18.99),
    ("Large Margherita Pizza", "Pizza", "Large", 17.49),
    ("Medium Pepperoni Pizza", "Pizza", "Medium", 15.99),
    ("Medium Margherita Pizza", "Pizza", "Medium", 15.49),
    ("Large Veggie Supreme", "Pizza", "Large", 19.99),
    ("Large Meat Lovers", "Pizza", "Large", 20.99),
    ("Large Hawaiian Pizza", "Pizza", "Large", 18.49),
    ("Large BBQ Chicken Pizza", "Pizza", "Large", 21.99),
    ("Large Four Cheese Pizza", "Pizza", "Large", 18.99),
    ("Large Buffalo Chicken Pizza", "Pizza", "Large", 22.49),
    ("Large Supreme Pizza", "Pizza", "Large", 22.99),
    ("Small Cheese Pizza", "Pizza", "Small", 11.99),
    ("Medium Cheese Pizza", "Pizza", "Medium", 13.99),
    ("Large Garlic Knots", "Side", "Large", 8.99),
    ("Classic Caesar Salad", "Side", "Regular", 9.49),
    ("Garden Salad", "Side", "Regular", 8.99),
    ("House Fries", "Side", "Regular", 5.49),
    ("Chocolate Brownie", "Dessert", "Single", 4.99),
    ("Lemonade", "Drink", "500ml", 3.49),
    ("Coca-Cola", "Drink", "500ml", 3.29),
    ("Sparkling Water", "Drink", "500ml", 2.99),
    ("Iced Tea", "Drink", "500ml", 3.49),
    ("Espresso", "Drink", "Regular", 3.99),
    ("Cheese Bread", "Side", "Large", 10.49),
    ("Stuffed Calzone", "Pizza", "Large", 16.49),
]

INGREDIENT_NAMES = [
    "Mozzarella Cheese", "Pepperoni", "Pizza Dough", "Tomato Sauce", "Olive Oil",
    "Basil", "Red Onions", "Bell Peppers", "Mushrooms", "Spinach", "Chicken",
    "Italian Sausage", "Ham", "Bacon", "Pineapple", "Jalapeno", "Garlic",
    "Parmesan", "Oregano", "Feta Cheese", "Arugula", "Sweet Corn", "Black Olives",
    "Anchovies", "Beef", "Lime", "Lemon", "Cucumber", "Tomato", "Lettuce",
    "Cabbage", "Romaine", "Broccoli", "Carrots", "Green Beans", "Avocado",
    "Guacamole", "Salsa", "Cilantro", "Cumin", "Paprika", "Chili Flakes",
    "Butter", "Milk", "Cream", "Flour", "Sugar", "Vanilla",
]


def get_db_config():
    required = (
        "AZURE_DB_HOST",
        "AZURE_DB_NAME",
        "AZURE_DB_USER",
        "AZURE_DB_PASSWORD",
    )
    config = {key: os.getenv(key) for key in required}
    missing = [key for key, value in config.items() if not value]
    if missing:
        raise RuntimeError(
            "Missing required database settings: " + ", ".join(missing)
            + ". Copy .env.example to .env and populate the Azure connection values."
        )

    config["port"] = os.getenv("AZURE_DB_PORT", "5432")
    return config


def get_connection():
    config = get_db_config()
    return psycopg2.connect(
        host=config["AZURE_DB_HOST"],
        dbname=config["AZURE_DB_NAME"],
        user=config["AZURE_DB_USER"],
        password=config["AZURE_DB_PASSWORD"],
        port=config["port"],
        sslmode="require",
    )


def insert_rows(cursor, table_name, columns, rows):
    if not rows:
        return
    query = sql.SQL("INSERT INTO {} ({}) VALUES ({})").format(
        sql.Identifier(table_name),
        sql.SQL(", ").join(map(sql.Identifier, columns)),
        sql.SQL(", ").join(sql.Placeholder() for _ in columns),
    )
    execute_batch(cursor, query.as_string(cursor), rows, page_size=500)


def seed_stores(cursor):
    cities = ["Seattle", "Portland", "Denver", "Austin"]
    addresses = ["1201 Pine St", "216 Broadway Ave", "789 Market St", "4500 5th Ave"]
    phone_prefixes = ["206", "503", "303", "512"]
    rows = [
        (
            addresses[index],
            cities[index],
            f"{phone_prefixes[index]}-{random.randint(100, 999)}-{random.randint(1000, 9999)}",
            DATA_AS_OF - timedelta(days=random.randint(365, 3650)),
        )
        for index in range(STORES)
    ]
    insert_rows(cursor, "stores", ["address", "city", "phone_number", "opened_at"], rows)


def seed_ingredients(cursor):
    rows = [
        (name, round(random.uniform(50, 2500), 2), random.choice(["kg", "liters", "units", "bags"]))
        for name in INGREDIENT_NAMES[:INGREDIENTS]
    ]
    insert_rows(cursor, "ingredients", ["name", "stock_quantity", "unit"], rows)
    cursor.execute("SELECT ingredient_id, name FROM ingredients ORDER BY ingredient_id")
    return {name: ingredient_id for ingredient_id, name in cursor.fetchall()}


def seed_menu_items(cursor):
    insert_rows(cursor, "menu_items", ["name", "category", "size", "price"], MENU_DATA)
    cursor.execute("SELECT item_id FROM menu_items ORDER BY item_id")
    return [row[0] for row in cursor.fetchall()]


def seed_menu_item_ingredients(cursor, menu_item_ids, ingredient_lookup):
    ingredient_ids = list(ingredient_lookup.values())
    rows = []
    for item_id in menu_item_ids:
        for ingredient_id in random.sample(ingredient_ids, random.randint(2, 6)):
            rows.append(
                (
                    item_id,
                    ingredient_id,
                    round(random.uniform(0.1, 3.5), 2),
                    random.choice(["kg", "liters", "units", "cups"]),
                )
            )
    insert_rows(
        cursor,
        "menu_item_ingredients",
        ["menu_item_id", "ingredient_id", "quantity", "unit"],
        rows,
    )


def seed_customers(cursor):
    rows = []
    for index in range(CUSTOMERS):
        first = fake.first_name()
        last = fake.last_name()
        email = f"{first.lower()}.{last.lower()}.{index}@example.com"
        phone = f"555-{index // 10_000:04d}-{index % 10_000:04d}"
        created_at = fake.date_time_between(
            start_date=datetime(2020, 1, 1), end_date=DATA_AS_OF
        )
        rows.append((first, last, email, phone, created_at))
    insert_rows(
        cursor,
        "customers",
        ["first_name", "last_name", "email", "phone_number", "created_at"],
        rows,
    )


def seed_orders(cursor):
    start_of_year = datetime(DATA_AS_OF.year, 1, 1)
    rows = [
        (
            random.randint(1, CUSTOMERS),
            random.randint(1, STORES),
            fake.date_time_between(start_date=start_of_year, end_date=DATA_AS_OF),
            round(random.uniform(10, 60), 2),
        )
        for _ in range(ORDERS)
    ]
    insert_rows(
        cursor,
        "orders",
        ["customer_id", "store_id", "order_timestamp", "total_amount"],
        rows,
    )
    cursor.execute("SELECT order_id FROM orders ORDER BY order_id")
    return [row[0] for row in cursor.fetchall()]


def seed_order_items(cursor, order_ids, menu_item_prices):
    minimum_items = 2 * len(order_ids)
    maximum_items = 3 * len(order_ids)
    if not minimum_items <= TARGET_ORDER_ITEMS <= maximum_items:
        raise ValueError("TARGET_ORDER_ITEMS must be between two and three items per order.")

    extra_item_count = TARGET_ORDER_ITEMS - minimum_items
    orders_with_extra_item = set(random.sample(order_ids, extra_item_count))
    rows = []
    for order_id in order_ids:
        item_count = 3 if order_id in orders_with_extra_item else 2
        for _ in range(item_count):
            item_id, unit_price = random.choice(menu_item_prices)
            rows.append((order_id, item_id, random.randint(1, 2), unit_price))

    insert_rows(
        cursor,
        "order_items",
        ["order_id", "item_id", "quantity", "unit_price"],
        rows,
    )


def main():
    connection = get_connection()
    try:
        with connection:
            with connection.cursor() as cursor:
                seed_stores(cursor)
                ingredient_lookup = seed_ingredients(cursor)
                menu_item_ids = seed_menu_items(cursor)
                seed_menu_item_ingredients(cursor, menu_item_ids, ingredient_lookup)
                seed_customers(cursor)
                order_ids = seed_orders(cursor)
                cursor.execute("SELECT item_id, price FROM menu_items ORDER BY item_id")
                menu_item_prices = [(item_id, float(price)) for item_id, price in cursor.fetchall()]
                seed_order_items(cursor, order_ids, menu_item_prices)

                print("RushMore data load complete.")
                for table in ("stores", "customers", "orders", "order_items"):
                    cursor.execute(sql.SQL("SELECT COUNT(*) FROM {}").format(sql.Identifier(table)))
                    print(f"{table.replace('_', ' ').title()}:", cursor.fetchone()[0])
    finally:
        connection.close()


if __name__ == "__main__":
    main()
