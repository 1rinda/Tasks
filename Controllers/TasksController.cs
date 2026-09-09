using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TodoApi.Data;
using TodoApi.Models;

namespace TodoApi.Controllers;

[ApiController]
[Route("api/tasks")]
public class TasksController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<TodoTask>>> GetAll() =>
        await db.Tasks.AsNoTracking().OrderBy(t => t.Id).ToListAsync();

    [HttpGet("{id:int}")]
    public async Task<ActionResult<TodoTask>> Get(int id) =>
        await db.Tasks.FindAsync(id) is { } task ? Ok(task) : NotFound();

    [HttpPost]
    public async Task<ActionResult<TodoTask>> Create(TaskInput input)
    {
        var task = new TodoTask
        {
            Title = input.Title.Trim(), Description = input.Description,
            IsCompleted = input.IsCompleted, DueDate = input.DueDate
        };
        db.Tasks.Add(task);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(Get), new { id = task.Id }, task);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, TaskInput input)
    {
        var task = await db.Tasks.FindAsync(id);
        if (task is null) return NotFound();
        task.Title = input.Title.Trim();
        task.Description = input.Description;
        task.IsCompleted = input.IsCompleted;
        task.DueDate = input.DueDate;
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var task = await db.Tasks.FindAsync(id);
        if (task is null) return NotFound();
        db.Tasks.Remove(task);
        await db.SaveChangesAsync();
        return NoContent();
    }
}

public class TaskInput
{
    [Required]
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? DueDate { get; set; }
}
