#!/usr/bin/env python3
"""
Test HTML report rendering using Playwright
Checks that all elements are properly displayed
"""

import os
import sys
from pathlib import Path

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    print("Installing playwright...")
    os.system("pip install playwright")
    os.system("playwright install chromium")
    from playwright.sync_api import sync_playwright

def test_report_rendering(html_file):
    """Test that HTML report renders correctly"""

    # Convert to absolute path
    html_path = Path(html_file).absolute()
    if not html_path.exists():
        print(f"❌ Error: File not found: {html_path}")
        return False

    with sync_playwright() as p:
        # Launch browser
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        # Load the HTML file
        file_url = f"file://{html_path}"
        print(f"Loading: {file_url}")
        page.goto(file_url, wait_until="networkidle")

        # Wait for content to load
        page.wait_for_load_state("domcontentloaded")
        page.wait_for_timeout(2000)  # Wait 2 seconds for any dynamic content

        # Check for key elements
        checks = {
            "Title": page.title(),
            "TOC Present": page.locator(".tocify").count() > 0,
            "Main Content": page.locator(".main-container").count() > 0,
            "Figures": page.locator("img").count(),
            "Tables": page.locator("table").count(),
            "Executive Summary": page.locator(".summary-box").count() > 0,
            "Key Findings": page.locator(".key-finding").count(),
            "Code Blocks Hidden": page.locator("pre:visible").count() == 0,
        }

        # Print results
        print("\n=== RENDERING TEST RESULTS ===\n")
        all_passed = True

        for check, result in checks.items():
            if isinstance(result, bool):
                status = "✓" if result else "✗"
                print(f"{status} {check}: {'Present' if result else 'Missing'}")
                if not result:
                    all_passed = False
            elif isinstance(result, int):
                status = "✓" if result > 0 else "⚠"
                print(f"{status} {check}: {result}")
                if check in ["Figures", "Tables"] and result == 0:
                    all_passed = False
            else:
                print(f"ℹ {check}: {result}")

        # Check for errors in console
        console_errors = []
        page.on("console", lambda msg: console_errors.append(msg.text) if msg.type == "error" else None)
        page.reload()
        page.wait_for_timeout(1000)

        if console_errors:
            print(f"\n⚠ Console Errors: {len(console_errors)}")
            for error in console_errors[:3]:  # Show first 3 errors
                print(f"  - {error[:100]}...")
        else:
            print("\n✓ No console errors")

        # Take a screenshot
        screenshot_path = html_path.parent / "report_screenshot.png"
        page.set_viewport_size({"width": 1920, "height": 1080})
        page.screenshot(path=str(screenshot_path), full_page=False)
        print(f"\n📸 Screenshot saved: {screenshot_path}")

        # Get page dimensions
        dimensions = page.evaluate("""
            () => {
                return {
                    width: document.documentElement.scrollWidth,
                    height: document.documentElement.scrollHeight,
                    viewport: {
                        width: window.innerWidth,
                        height: window.innerHeight
                    }
                }
            }
        """)

        print(f"\n📐 Page Dimensions:")
        print(f"  Full: {dimensions['width']}x{dimensions['height']}px")
        print(f"  Viewport: {dimensions['viewport']['width']}x{dimensions['viewport']['height']}px")

        # Check responsive design
        mobile_width = 375
        page.set_viewport_size({"width": mobile_width, "height": 812})
        page.wait_for_timeout(500)

        mobile_toc = page.locator(".tocify:visible").count()
        print(f"\n📱 Mobile View ({mobile_width}px):")
        print(f"  TOC Hidden: {'✓' if mobile_toc == 0 else '✗'}")

        browser.close()

        return all_passed

def main():
    """Main function"""
    report_file = "reports/Complete_Analysis_Enhanced.html"

    print("=" * 50)
    print("HTML REPORT RENDERING TEST")
    print("=" * 50)

    if test_report_rendering(report_file):
        print("\n✅ ALL TESTS PASSED - Report renders correctly!")
        return 0
    else:
        print("\n⚠️  Some issues detected - Review the report manually")
        return 1

if __name__ == "__main__":
    sys.exit(main())