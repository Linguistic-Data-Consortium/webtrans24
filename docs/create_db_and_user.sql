-- NOTE: make sure both the database and password are configured appropriately before running
CREATE DATABASE webtrans;
CREATE USER webtrans WITH password 'change-me-to-a-better-password';
ALTER DATABASE webtrans OWNER TO webtrans;
