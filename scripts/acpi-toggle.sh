if [ "$HOSTNAME" = "Mikan" ]; then
	if [[ "$1" == "performance" ]]; then
		pkexec echo '\_SB.PCI0.LPC0.EC0.VPC0.DYTC 0x0012B001' | pkexec tee /proc/acpi/call >/dev/null
		notify-send 'ACPI methods toggle' 'Extreme Performance mode 🔥'
	elif [[ "$1" == "battery" ]]; then
		pkexec echo '\_SB.PCI0.LPC0.EC0.VPC0.DYTC 0x0013B001' | pkexec tee /proc/acpi/call >/dev/null
		notify-send 'ACPI methods toggle' 'Battery Saving mode 🔋'
	else
		notify-send 'wrong argument' "$1"
	fi
else
	notify-send 'wrong host' 'ACPI method is not supported on this machine'
fi
