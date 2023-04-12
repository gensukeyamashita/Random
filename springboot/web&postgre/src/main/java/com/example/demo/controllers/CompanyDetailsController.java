package com.example.demo.controllers;

import com.example.demo.repositories.CompanyDetailsRepository;
import com.example.demo.tables.CompanyDetails;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.List;

@Controller
public class CompanyDetailsController {
    @Autowired
    private CompanyDetailsRepository companyDetailsrepository;

    @GetMapping("/company-details")
    public ResponseEntity<List<CompanyDetails> > listAll(Model model) {
        List<CompanyDetails> listCoDetails = companyDetailsrepository.findAll();
        return new ResponseEntity(listCoDetails, HttpStatus.OK);
    }
}
