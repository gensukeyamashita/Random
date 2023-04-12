package com.example.demo.repositories;

import com.example.demo.tables.CompanyDetails;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CompanyDetailsRepository extends JpaRepository<CompanyDetails, Integer> {
}
