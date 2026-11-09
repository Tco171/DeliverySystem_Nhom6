using Back_DeliverySystem.Models;
using Microsoft.EntityFrameworkCore;

namespace Back_DeliverySystem.Data;

public static class Sprint3SeedData
{
    public static async Task InitializeAsync(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        await SeedAreasAsync(context);
        await SeedStaffAreasAsync(context);
        await BackfillAssignmentSourcesAsync(context);
    }

    private static async Task SeedAreasAsync(AppDbContext context)
    {
        var areas = new[]
        {
            new Area
            {
                Code = "HCM-HOA-HUNG",
                Name = "Phường Hòa Hưng",
                Type = "ward",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            },
            new Area
            {
                Code = "HCM-TAN-HOA",
                Name = "Phường Tân Hòa",
                Type = "ward",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            }
        };

        foreach (var area in areas)
        {
            var existed = await context.Areas.AnyAsync(x => x.Code == area.Code);
            if (!existed)
            {
                context.Areas.Add(area);
            }
        }

        await context.SaveChangesAsync();
    }

    private static async Task SeedStaffAreasAsync(AppDbContext context)
    {
        var hoaHung = await context.Areas.FirstOrDefaultAsync(x => x.Code == "HCM-HOA-HUNG");
        var tanHoa = await context.Areas.FirstOrDefaultAsync(x => x.Code == "HCM-TAN-HOA");

        if (hoaHung == null || tanHoa == null)
        {
            return;
        }

        var staffs = await context.Staffs
            .OrderBy(x => x.Id)
            .Take(2)
            .ToListAsync();

        if (staffs.Count == 0)
        {
            return;
        }

        await EnsureStaffAreaAsync(context, staffs[0].Id, hoaHung.Id, 3);
        await EnsureStaffAreaAsync(context, staffs[0].Id, tanHoa.Id, 4);
        staffs[0].Area = "Phường Hòa Hưng, Phường Tân Hòa";

        if (staffs.Count >= 2)
        {
            await EnsureStaffAreaAsync(context, staffs[1].Id, hoaHung.Id, 5);
            staffs[1].Area = "Phường Hòa Hưng";
        }

        await context.SaveChangesAsync();
    }

    private static async Task EnsureStaffAreaAsync(
        AppDbContext context,
        int staffId,
        int areaId,
        int maxActiveOrders)
    {
        var staffArea = await context.StaffAreas.FirstOrDefaultAsync(x =>
            x.StaffId == staffId && x.AreaId == areaId);

        if (staffArea == null)
        {
            context.StaffAreas.Add(new StaffArea
            {
                StaffId = staffId,
                AreaId = areaId,
                MaxActiveOrders = maxActiveOrders,
                IsActive = true,
                AssignedAt = DateTime.UtcNow
            });
            return;
        }

        staffArea.MaxActiveOrders = maxActiveOrders;
        staffArea.IsActive = true;
    }

    private static async Task BackfillAssignmentSourcesAsync(AppDbContext context)
    {
        var legacyAssignments = await context.DeliveryAssignments
            .Where(x => x.AssignmentSource == null || x.AssignmentSource == "")
            .ToListAsync();

        if (legacyAssignments.Count == 0)
        {
            return;
        }

        foreach (var assignment in legacyAssignments)
        {
            assignment.AssignmentSource = "manual";
        }

        await context.SaveChangesAsync();
    }
}
