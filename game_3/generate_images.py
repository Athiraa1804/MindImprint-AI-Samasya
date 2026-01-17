import requests
import json
from PIL import Image, ImageDraw, ImageFont
import os
import math

# Create assets/images directory if it doesn't exist
os.makedirs('assets/images', exist_ok=True)

def get_image_description(game_name, game_type):
    """Get image description from Ollama"""
    prompt = f"""Generate a detailed visual description for a child-friendly illustration for "{game_name}".
    Type: {game_type}
    
    Describe specific visual elements:
    - Main objects/shapes
    - Colors (list 3-4 specific colors)
    - Layout composition
    - Key symbols or icons
    
    Keep it concise (2-3 sentences). Be specific about what visual elements to draw."""
    
    try:
        response = requests.post(
            'http://localhost:11434/api/generate',
            json={"model": "mistral", "prompt": prompt, "stream": False},
            timeout=30
        )
        if response.status_code == 200:
            result = response.json().get('response', '')
            print(f"  Ollama: {result[:150]}...")
            return result
    except Exception as e:
        print(f"  Note: Ollama unavailable ({e})")
    return None

def create_step_sequencing_image(filename):
    """Create a step sequencing illustration"""
    print("📝 Creating Step Sequencing image...")
    
    width, height = 400, 320
    img = Image.new('RGB', (width, height), color=(230, 240, 255))
    draw = ImageDraw.Draw(img)
    
    # Get AI description
    description = get_image_description("Step Sequencing", "Memory ordering and sequence recall game")
    
    # Draw background gradient (light blue)
    for y in range(height):
        ratio = y / height
        r = int(230 * (1 - ratio) + 100 * ratio)
        g = int(240 * (1 - ratio) + 150 * ratio)
        b = int(255 * (1 - ratio) + 220 * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    
    # Draw 6 numbered steps as boxes
    step_width = 50
    step_height = 50
    spacing = 15
    start_x = (width - (6 * step_width + 5 * spacing)) // 2
    start_y = 100
    
    colors = [(100, 150, 255), (120, 170, 255), (140, 180, 255), (160, 190, 255), (180, 200, 255), (200, 210, 255)]
    
    for i in range(6):
        x = start_x + i * (step_width + spacing)
        y = start_y
        
        # Draw box
        draw.rectangle([(x, y), (x + step_width, y + step_height)], fill=colors[i], outline=(50, 100, 200), width=2)
        
        # Draw number
        try:
            font = ImageFont.truetype("arial.ttf", 24)
        except:
            font = ImageFont.load_default()
        
        text = str(i + 1)
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        text_x = x + (step_width - text_width) // 2
        text_y = y + (step_height - text_height) // 2
        
        draw.text((text_x, text_y), text, fill=(255, 255, 255), font=font)
    
    # Draw arrows between steps
    arrow_y = start_y + step_height + 15
    for i in range(5):
        x1 = start_x + (i + 1) * step_width + i * spacing
        x2 = x1 + spacing - 5
        draw.line([(x1, arrow_y), (x2, arrow_y)], fill=(100, 150, 255), width=2)
        draw.polygon([(x2, arrow_y - 5), (x2 + 5, arrow_y), (x2, arrow_y + 5)], fill=(100, 150, 255))
    
    # Draw title
    try:
        title_font = ImageFont.truetype("arial.ttf", 28)
    except:
        title_font = ImageFont.load_default()
    
    title = "Step Sequencing"
    bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = bbox[2] - bbox[0]
    title_x = (width - title_width) // 2
    
    draw.text((title_x, 20), title, fill=(255, 255, 255), font=title_font)
    
    # Resize and save
    img = img.resize((200, 160), Image.Resampling.LANCZOS)
    img.save(filename)
    print(f"  ✅ Saved: {filename}\n")

def create_story_reading_image(filename):
    """Create a story reading illustration"""
    print("📖 Creating Story Reading image...")
    
    width, height = 400, 320
    img = Image.new('RGB', (width, height), color=(240, 220, 255))
    draw = ImageDraw.Draw(img)
    
    # Get AI description
    description = get_image_description("Story Reading", "Reading comprehension and attention focus")
    
    # Draw background gradient (purple)
    for y in range(height):
        ratio = y / height
        r = int(240 * (1 - ratio) + 120 * ratio)
        g = int(220 * (1 - ratio) + 100 * ratio)
        b = int(255 * (1 - ratio) + 200 * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    
    # Draw an open book
    book_left = width // 2 - 80
    book_top = 80
    book_width = 160
    book_height = 140
    
    # Book cover (left page)
    draw.rectangle(
        [(book_left, book_top), (book_left + book_width // 2, book_top + book_height)],
        fill=(200, 100, 150),
        outline=(100, 50, 100),
        width=2
    )
    
    # Book pages (right page)
    draw.rectangle(
        [(book_left + book_width // 2, book_top), (book_left + book_width, book_top + book_height)],
        fill=(255, 250, 200),
        outline=(100, 50, 100),
        width=2
    )
    
    # Draw text lines on pages
    line_color = (150, 100, 120)
    line_y = book_top + 15
    for _ in range(5):
        draw.rectangle(
            [(book_left + book_width // 2 + 10, line_y), (book_left + book_width - 10, line_y + 4)],
            fill=line_color
        )
        line_y += 20
    
    # Draw a bookmark
    draw.rectangle([(book_left + book_width - 15, book_top - 10), (book_left + book_width - 5, book_top + book_height + 10)],
                   fill=(255, 100, 100))
    
    # Draw stars around the book (indicating story)
    for i in range(4):
        angle = i * math.pi / 2
        star_x = width // 2 + 120 * math.cos(angle)
        star_y = book_top + book_height // 2 + 80 * math.sin(angle)
        draw.ellipse([(star_x - 8, star_y - 8), (star_x + 8, star_y + 8)], fill=(255, 200, 100))
    
    # Draw title
    try:
        title_font = ImageFont.truetype("arial.ttf", 28)
    except:
        title_font = ImageFont.load_default()
    
    title = "Story Reading"
    bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = bbox[2] - bbox[0]
    title_x = (width - title_width) // 2
    
    draw.text((title_x, 20), title, fill=(255, 255, 255), font=title_font)
    
    # Resize and save
    img = img.resize((200, 160), Image.Resampling.LANCZOS)
    img.save(filename)
    print(f"  ✅ Saved: {filename}\n")

def create_reaction_time_image(filename):
    """Create a reaction time illustration"""
    print("⚡ Creating Reaction Time image...")
    
    width, height = 400, 320
    img = Image.new('RGB', (width, height), color=(255, 240, 200))
    draw = ImageDraw.Draw(img)
    
    # Get AI description
    description = get_image_description("Reaction Time", "Speed and focus response to visual stimuli")
    
    # Draw background gradient (orange to red)
    for y in range(height):
        ratio = y / height
        r = int(255 * (1 - ratio) + 220 * ratio)
        g = int(240 * (1 - ratio) + 100 * ratio)
        b = int(200 * (1 - ratio) + 80 * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    
    # Draw a target/bullseye
    center_x, center_y = width // 2, height // 2 - 20
    
    # Circles for bullseye
    circle_colors = [(255, 100, 80), (255, 150, 100), (255, 200, 150), (255, 230, 200)]
    circle_radii = [70, 50, 30, 10]
    
    for i, (color, radius) in enumerate(zip(circle_colors, circle_radii)):
        draw.ellipse(
            [(center_x - radius, center_y - radius), (center_x + radius, center_y + radius)],
            fill=color,
            outline=(100, 50, 30),
            width=2
        )
    
    # Draw speed lines around the target
    for angle in range(0, 360, 45):
        rad = math.radians(angle)
        x1 = center_x + 90 * math.cos(rad)
        y1 = center_y + 90 * math.sin(rad)
        x2 = center_x + 120 * math.cos(rad)
        y2 = center_y + 120 * math.sin(rad)
        draw.line([(x1, y1), (x2, y2)], fill=(255, 200, 150), width=3)
    
    # Draw lightning bolt symbol
    bolt_x = width // 2 - 50
    bolt_y = height - 80
    bolt_points = [(bolt_x, bolt_y), (bolt_x + 15, bolt_y + 25), (bolt_x + 5, bolt_y + 25),
                   (bolt_x + 20, bolt_y + 50), (bolt_x - 10, bolt_y + 30), (bolt_x, bolt_y + 30)]
    draw.polygon(bolt_points, fill=(255, 255, 100), outline=(255, 150, 0), width=2)
    
    # Draw title
    try:
        title_font = ImageFont.truetype("arial.ttf", 28)
    except:
        title_font = ImageFont.load_default()
    
    title = "Reaction Time"
    bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = bbox[2] - bbox[0]
    title_x = (width - title_width) // 2
    
    draw.text((title_x, 20), title, fill=(255, 255, 255), font=title_font)
    
    # Resize and save
    img = img.resize((200, 160), Image.Resampling.LANCZOS)
    img.save(filename)
    print(f"  ✅ Saved: {filename}\n")

# Generate all images
print("🎨 Generating game-specific images from AI descriptions...\n")

create_step_sequencing_image('assets/images/step_sequencing.png')
create_story_reading_image('assets/images/story_reading.png')
create_reaction_time_image('assets/images/reaction_time.png')

print("✨ All game images generated successfully!")
print("📁 Location: assets/images/")

