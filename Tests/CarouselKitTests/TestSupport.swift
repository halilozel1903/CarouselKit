/// Whether two doubles are equal up to rounding.
func isClose(_ lhs: Double, _ rhs: Double, tolerance: Double = 1e-9) -> Bool {
    abs(lhs - rhs) <= tolerance
}
