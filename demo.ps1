Write-Host "=====================================" -ForegroundColor Green
Write-Host "SMART TICKETING SYSTEM - DEMO" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

Write-Host "`nWaiting for services to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

try {
    # 1. Register Passenger
    Write-Host "`n[1/7] Registering passenger..." -ForegroundColor Cyan
    $registerBody = @{
        username = "Demo User"
        email = "demo@windhoek.na"
        password = "secure123"
    } | ConvertTo-Json

    Invoke-RestMethod -Uri "<http://localhost:9090/passenger/register>" `
        -Method Post `
        -ContentType "application/json" `
        -Body $registerBody | Out-Null

    Write-Host "      ✅ Passenger registered successfully" -ForegroundColor Green

    # 2. Login
    Write-Host "`n[2/7] Logging in..." -ForegroundColor Cyan
    $loginBody = @{
        email = "demo@windhoek.na"
        password = "secure123"
    } | ConvertTo-Json

    $login = Invoke-RestMethod -Uri "<http://localhost:9090/passenger/login>" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody

    $userId = $login.userId
    Write-Host "      ✅ Logged in as: $($login.username)" -ForegroundColor Green
    Write-Host "      User ID: $userId" -ForegroundColor Gray

    # 3. Create Route
    Write-Host "`n[3/7] Creating bus route..." -ForegroundColor Cyan
    $routeBody = @{
        name = "Downtown Express - Route 101"
        routeType = "bus"
        stops = @("Main Station", "City Center", "Shopping Mall", "University")
        schedule = @{
            weekdays = @("06:00", "08:00", "17:00", "19:00")
            weekends = @("09:00", "14:00", "18:00")
        }
    } | ConvertTo-Json

    $route = Invoke-RestMethod -Uri "<http://localhost:9094/transport/routes>" `
        -Method Post `
        -ContentType "application/json" `
        -Body $routeBody

    $routeId = $route.routeId
    Write-Host "      ✅ Route created successfully" -ForegroundColor Green
    Write-Host "      Route ID: $routeId" -ForegroundColor Gray

    # 4. Create Trip
    Write-Host "`n[4/7] Scheduling a trip..." -ForegroundColor Cyan
    $tripBody = @{
        routeId = $routeId
        departureTime = "2024-12-20T08:00:00Z"
        arrivalTime = "2024-12-20T09:30:00Z"
        vehicleId = "BUS-101"
    } | ConvertTo-Json

    $trip = Invoke-RestMethod -Uri "<http://localhost:9094/transport/trips>" `
        -Method Post `
        -ContentType "application/json" `
        -Body $tripBody

    $tripId = $trip.tripId
    Write-Host "      ✅ Trip scheduled successfully" -ForegroundColor Green
    Write-Host "      Trip ID: $tripId" -ForegroundColor Gray

    # 5. Purchase Ticket
    Write-Host "`n[5/7] Purchasing ticket..." -ForegroundColor Cyan
    $ticketBody = @{
        userId = $userId
        tripId = $tripId
        ticketType = "single"
        price = 5.50
    } | ConvertTo-Json

    $ticket = Invoke-RestMethod -Uri "<http://localhost:9091/ticketing/tickets>" `
        -Method Post `
        -ContentType "application/json" `
        -Body $ticketBody

    $ticketId = $ticket.ticketId
    Write-Host "      ✅ Ticket purchased successfully" -ForegroundColor Green
    Write-Host "      Ticket ID: $ticketId" -ForegroundColor Gray
    Write-Host "      Status: $($ticket.status)" -ForegroundColor Gray

    Write-Host "`n      ⏳ Processing payment..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5

    # 6. View User Tickets
    Write-Host "`n[6/7] Viewing passenger tickets..." -ForegroundColor Cyan
    $userTickets = Invoke-RestMethod -Uri "<http://localhost:9090/passenger/tickets/$userId>" `
        -Method Get

    Write-Host "      ✅ User has $($userTickets.Count) ticket(s)" -ForegroundColor Green

    # 7. Admin Sales Report
    Write-Host "`n[7/7] Generating admin sales report..." -ForegroundColor Cyan
    $salesReport = Invoke-RestMethod -Uri "<http://localhost:9093/admin/reports/sales>" `
        -Method Get

    Write-Host "      ✅ Sales Report Generated" -ForegroundColor Green
    Write-Host "      ----------------------------------------" -ForegroundColor White
    Write-Host "      Total Tickets Sold:      $($salesReport.totalTickets)" -ForegroundColor White
    Write-Host "      Successful Payments:     $($salesReport.successfulPayments)" -ForegroundColor White
    Write-Host "      Total Revenue:           NAD $($salesReport.totalRevenue)" -ForegroundColor White
    Write-Host "      ----------------------------------------" -ForegroundColor White

    # Success
    Write-Host "`n=====================================" -ForegroundColor Green
    Write-Host "✅ DEMO COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green

    Write-Host "`nSystem URLs:" -ForegroundColor Yellow
    Write-Host "  🚌 Passenger Service:  <http://localhost:9090>" -ForegroundColor White
    Write-Host "  🎫 Ticketing Service:  <http://localhost:9091>" -ForegroundColor White
    Write-Host "  🚍 Transport Service:  <http://localhost:9094>" -ForegroundColor White
    Write-Host "  👨‍💼 Admin Service:      <http://localhost:9093>" -ForegroundColor White
    Write-Host "`n" -ForegroundColor White

} catch {
    Write-Host "`n=====================================" -ForegroundColor Red
    Write-Host "❌ DEMO FAILED!" -ForegroundColor Red
    Write-Host "=====================================" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check service status: docker-compose ps" -ForegroundColor White
    Write-Host "  2. View logs: docker-compose logs -f" -ForegroundColor White
    Write-Host "  3. Restart: docker-compose restart" -ForegroundColor White
    exit 1
}
