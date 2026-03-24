# VoltShare — Global EV Charging Network Simulation

VoltShare is a comprehensive Oracle SQL database project designed to simulate a global electric vehicle (EV) charging network. This project was developed for the **Data Management 2** module at **NIBM School of Computing & Engineering**.

🔌 Project Overview
VoltShare manages a complex ecosystem of charging stations, operators, users, and financial transactions across multiple countries. It features a normalized relational schema with 10 tables, automated primary key generation via sequences, and advanced business logic implemented through PL/SQL.

Key Features:
* [cite_start]**Multi-Country Support:** Manages stations in Sri Lanka, Germany, USA, Japan, and Norway[cite: 1].
* [cite_start]**Tiered Membership:** Supports BASIC, SILVER, GOLD, and PLATINUM user tiers with automated wallet balance checks[cite: 1, 2].
* [cite_start]**Real-time Monitoring:** Tracks charger statuses (Available, In-Use, Faulted, Offline)[cite: 1].
* [cite_start]**Automated Logic:** Includes stored procedures for starting/ending sessions and generating reports[cite: 2].
* [cite_start]**Role-Based Security:** Implements specific privileges for Drivers, Operators, Analysts, and Admins[cite: 2].

🛠️ Technical Stack
* **Database:** Oracle SQL
* **Language:** SQL, PL/SQL
* **Tools:** Oracle SQL Developer

📊 Database Schema
The system consists of the following 10 core tables:
1. [cite_start]`countries` & `cities` - Geographic location management[cite: 1].
2. [cite_start]`operators` - Companies managing the charging infrastructure[cite: 1].
3. [cite_start]`stations` & `chargers` - The physical charging hardware and locations[cite: 1].
4. [cite_start]`charger_types` - Specifications for different connectors (CCS, CHAdeMO, Type2)[cite: 1].
5. [cite_start]`users` & `vehicles` - Driver profiles and their registered EV details[cite: 1].
6. [cite_start]`charging_sessions` & `payments` - Transactional data and financial history[cite: 1].

🚀 Key Queries & PL/SQL Logic
The project includes several advanced SQL implementations:
* [cite_start]**6-Table Joins:** Comprehensive transaction history reports linking users, vehicles, and payments[cite: 2].
* [cite_start]**Conditional Logic:** Speed classification using `CASE` and wallet health checks using `DECODE`[cite: 2].
* [cite_start]**PL/SQL Blocks:** Use of explicit cursors, %ROWTYPE, and custom exception handling for robust data processing[cite: 2].
* [cite_start]**Stored Procedures:** `sp_start_session` and `sp_end_session` to handle real-time charging operations[cite: 2].




