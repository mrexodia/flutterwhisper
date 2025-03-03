import re
import subprocess
from decimal import Decimal
from datetime import datetime

def extract_dollar_amount(text):
    matches = re.findall(r'\$(\d+(?:\.\d+)?)', text)
    return sum(Decimal(amount) for amount in matches)

def main():
    try:
        # Get commit messages with dates
        result = subprocess.run(
            ['git', 'log', '--pretty=format:%ad|%s', '--date=iso'],
            capture_output=True,
            text=True,
            check=True
        )

        total = Decimal('0')
        commits = []

        for line in result.stdout.split('\n'):
            if not line:
                continue

            date_str, message = line.split('|', 1)
            amount = extract_dollar_amount(message)

            if amount > 0:
                date = datetime.fromisoformat(date_str.strip())
                formatted_date = date.strftime("%Y-%m-%d %H:%M:%S")
                commits.append((formatted_date, message.strip(), amount))
                total += amount

        if commits:
            # Calculate column widths
            date_width = max(len("Date"), len(commits[0][0]))
            message_width = max(len("Message"), max(len(commit[1]) for commit in commits))
            cost_width = max(len("Cost"), max(len(f"${commit[2]:.4f}") for commit in commits))

            # Print header
            print("-" * (date_width + message_width + cost_width + 6))
            print(f"{'Date'.ljust(date_width)} | {'Message'.ljust(message_width)} | {'Cost'.rjust(cost_width)}")
            print("-" * (date_width + message_width + cost_width + 6))

            # Print commits in reverse order
            for date, message, amount in reversed(commits):
                print(f"{date.ljust(date_width)} | {message.ljust(message_width)} | ${amount:>{cost_width-1}.4f}")

            print("-" * (date_width + message_width + cost_width + 6))
            print(f"\nTotal vibe coding cost: ${total:.2f}")
        else:
            print("No commits with costs found.")

    except subprocess.CalledProcessError as e:
        print("Error: Not a git repository or git command failed")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    main()