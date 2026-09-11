package payroll

import "testing"

func TestComputeSalary(t *testing.T) {
	cases := []struct {
		name                                      string
		basic, allowance, overtime, bonus, deduct float64
		wantGross, wantNet                        float64
	}{
		{"basic only", 5_000_000, 0, 0, 0, 0, 5_000_000, 5_000_000},
		{"full", 5_000_000, 1_000_000, 500_000, 300_000, 800_000, 6_800_000, 6_000_000},
		{"deduction exceeds", 1_000_000, 0, 0, 0, 1_200_000, 1_000_000, -200_000},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			gross, net := computeSalary(tc.basic, tc.allowance, tc.overtime, tc.bonus, tc.deduct)
			if gross != tc.wantGross {
				t.Errorf("gross = %v, want %v", gross, tc.wantGross)
			}
			if net != tc.wantNet {
				t.Errorf("net = %v, want %v", net, tc.wantNet)
			}
		})
	}
}
