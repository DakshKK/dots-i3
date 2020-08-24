#include <stdio.h>
#include <stdlib.h>

// When you can make command run as sudo
// Using SetUID - sudo chmod 4775
// Make binary executable of this and then run the script

int main (int argc, char *argv[]) {
	switch (atoi(argv[1])) {
		case 0:
			system("bash ./.scripts/.acpi_brightness.sh -dec");
			break;
		case 1:
			system("bash ./.scripts/.acpi_brightness.sh -inc");
			break;
	}
	return 0;
}
