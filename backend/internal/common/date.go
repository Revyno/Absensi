package common

import "time"

const DateLayout = "2006-01-02"

// ParseDate mengurai "YYYY-MM-DD". String kosong -> nil tanpa error.
func ParseDate(s string) (*time.Time, error) {
	if s == "" {
		return nil, nil
	}
	t, err := time.Parse(DateLayout, s)
	if err != nil {
		return nil, err
	}
	return &t, nil
}
