using GlassCollectorApi.Data;
using GlassCollectorApi.Services;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (Environment.GetEnvironmentVariable("PORT") != null)
{
    // If running on Railway/Cloud, use /tmp to ensure we have write permissions
    connectionString = "Data Source=/tmp/glasscollector.db";
}

builder.Services.AddDbContext<GlassCollectorDbContext>(options =>
    options.UseSqlite(connectionString));

builder.Services.AddSingleton<RouteOptimizationService>();
builder.Services.AddScoped<CollectionService>();

// AllowAll: permissive CORS for local Flutter development (emulator/device).
// Lock this down before production — restrict origins, methods, and headers.
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "GlassCollector API v1");
        options.RoutePrefix = "swagger";
    });
}

// Removed HttpsRedirection to prevent 502 infinite redirect loops on Railway proxy
app.UseCors("AllowAll");
app.MapControllers();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<GlassCollectorDbContext>();
    db.Database.Migrate();
    await DatabaseSeeder.SeedAsync(db);
}

app.Run();
