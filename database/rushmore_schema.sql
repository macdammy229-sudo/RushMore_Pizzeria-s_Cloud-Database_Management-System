# RushMore Pizzeria schema

BEGIN;

CREATE TABLE stores (
    store_id SERIAL PRIMARY KEY,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    opened_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ingredients (
    ingredient_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    stock_quantity NUMERIC(10,2) NOT NULL DEFAULT 0,
    unit VARCHAR(20) NOT NULL
);

CREATE TABLE menu_items (
    item_id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    size VARCHAR(20),
    price NUMERIC(8,2) NOT NULL DEFAULT 0,
    UNIQUE (name, category, size)
);

CREATE TABLE menu_item_ingredients (
    menu_item_id INTEGER NOT NULL,
    ingredient_id INTEGER NOT NULL,
    quantity NUMERIC(8,2) NOT NULL DEFAULT 1,
    unit VARCHAR(20) NOT NULL,
    PRIMARY KEY (menu_item_id, ingredient_id),
    CONSTRAINT fk_menu_item_ingredients_menu_item
        FOREIGN KEY (menu_item_id) REFERENCES menu_items(item_id) ON DELETE CASCADE,
    CONSTRAINT fk_menu_item_ingredients_ingredient
        FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id) ON DELETE CASCADE
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    store_id INTEGER NOT NULL,
    order_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount NUMERIC(10,2) NOT NULL,
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE SET NULL,
    CONSTRAINT fk_orders_store
        FOREIGN KEY (store_id) REFERENCES stores(store_id) ON DELETE RESTRICT
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    item_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price NUMERIC(8,2) NOT NULL,
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_item
        FOREIGN KEY (item_id) REFERENCES menu_items(item_id) ON DELETE RESTRICT,
    CONSTRAINT chk_order_items_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_order_items_price_positive CHECK (unit_price >= 0)
);

CREATE INDEX idx_orders_customer_id ON orders (customer_id);
CREATE INDEX idx_orders_store_id ON orders (store_id);
CREATE INDEX idx_orders_timestamp ON orders (order_timestamp);
CREATE INDEX idx_order_items_order_id ON order_items (order_id);
CREATE INDEX idx_order_items_item_id ON order_items (item_id);
CREATE INDEX idx_menu_item_ingredients_ingredient_id ON menu_item_ingredients (ingredient_id);

COMMIT;
