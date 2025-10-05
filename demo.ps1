Write-Host "SMART TICKETING SYSTEM DEMO" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

Start-Sleep -Seconds 2

# 1. Register
Write-Host "`n1. Registering passenger..." -ForegroundColor Cyan
Invoke-RestMethod -Uri "<http://localhost:9090/passenger/register>" -Method Post -ContentType "application/json" -Body (@{
    username = "Demo User"
    email = "demo@windhoek.na"
    password = "secure123"
} | ConvertTo-Json) | Out-Null
Write-Host "   ✅ Registered" -ForegroundColor Green

# 2. Login
Write-Host "`n2. Logging in..." -ForegroundColor Cyan
$login = Invoke-RestMethod -Uri "<http://localhost:9090/passenger/login>" -Method Post -ContentType "application/json" -Body (@{
    email = "demo@windhoek.na"
    password = "secure123"
} | ConvertTo-Json)
$userId = $login.userId
Write-Host "   ✅ Logged in: $($login.username)" -ForegroundColor Green

# 3. Create Route
Write-Host "`n3. Creating bus route..." -ForegroundColor Cyan
$route = Invoke-RestMethod -Uri "<http://localhost:9092/transport/routes>" -Method Post -ContentType "application/json" -Body (@{
    name = "Downtown Express"
    routeType = "bus"
    stops = @("Main Station", "City Center", "Mall")
    schedule = @{
        weekdays = @("08:00", "17:00")
    }
} | ConvertTo-Json)
Write-Host "   ✅ Route created: $($route.routeId)" -ForegroundColor Green

# 4. Create Trip
Write-Host "`n4. Scheduling trip..." -ForegroundColor Cyan
$trip = Invoke-RestMethod -Uri "<http://localhost:9092/transport/trips>" -Method Post -ContentType "application/json" -Body (@{
    routeId = $route.routeId
    departureTime = "2024-12-20T08:00:00Z"
    arrivalTime = "2024-12-20T09:00:00Z"
    vehicleId = "BUS-101"
} | ConvertTo-Json)
Write-Host "   ✅ Trip scheduled: $($trip.tripId)" -ForegroundColor Green

# 5. Buy Ticket
Write-Host "`n5. Purchasing ticket..." -ForegroundColor Cyan
$ticket = Invoke-RestMethod -Uri "<http://localhost:9091/ticketing/tickets>" -Method Post -ContentType "application/json" -Body (@{
    userId = $userId
    tripId = $trip.tripId
    ticketType = "single"
    price = 5.50
} | ConvertTo-Json)
Write-Host "   ✅ Ticket purchased: $($ticket.ticketId)" -ForegroundColor Green
Write-Host "   Status: $($ticket.status)" -ForegroundColor Yellow

# 6. Wait for payment
Write-Host "`n   ⏳ Processing payment..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 7. Sales Report
Write-Host "`n6. Generating admin report..." -ForegroundColor Cyan
$sales = Invoke-RestMethod -Uri "<http://localhost:9093/admin/reports/sales>"
Write-Host "   ✅ Sales Report:" -ForegroundColor Green
Write-Host "      Total Tickets: $($sales.totalTickets)" -ForegroundColor White
Write-Host "      Revenue: NAD $($sales.totalRevenue)" -ForegroundColor White

Write-Host "`n=============================" -ForegroundColor Green
Write-Host "✅ DEMO COMPLETE!" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green
